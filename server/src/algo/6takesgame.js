// 1. Classe Carte
class Carte {
    constructor(numero) {
        this.numero = numero;
        this.tetes = this.calculerTetes();
    }

    calculerTetes() {
        if (this.numero === 55) return 7;
        if (this.numero % 11 === 0) return 5;
        if (this.numero % 10 === 0) return 3;
        if (this.numero % 5 === 0) return 2;
        return 1;
    }

    get carteId() {
        return this.numero;
    }
}

// 2. Classe Deck
class Deck {
    cartes = [];
    constructor(empty = true) {
        if (typeof empty !== "boolean") throw new Error("Invalid argument type: must be a boolean!");
        if (empty) {
            for (let i = 1; i <= 104; i++) {
                this.cartes.push(new Carte(i));
            }
            this.melanger();
        }
    }

    melanger() {
        for (let i = this.cartes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [this.cartes[i], this.cartes[j]] = [this.cartes[j], this.cartes[i]];
        }
    }

    distribuer(n) {
        return this.cartes.splice(0, n);
    }
}

// 3. Classe Rang
class Rang {
    constructor(carte) {
        this.cartes = [carte];
    }

    ajouterCarte(carte) {
        let temp_carte= new Carte(carte.numero);    
        //comme ca meme si le client nous envoie une carte {numero } sans l'attribut tetes
        //on va nous meme calculer les tetes grace  au constructeur de la carte 
        this.cartes.push(temp_carte);
    }

    estPleine() {
        return this.cartes.length === 6;
    }

    recupererCartes()
    {   
        return this.cartes.splice(0, 5);
    }

    recupererCartes_special_case() {
        let carte = [];
        for (let i = 0; i < this.cartes.length; i++) {
            carte.push(this.cartes[i]);
        }
        return carte;
    }

    totalTetes() {
        return this.cartes.reduce((sum, c) => sum + c.tetes, 0);
    }

    // Fonction utilitaire pour le calcul de pénalité
    static calculerPenalite(cartes) {
        const total = cartes.reduce((sum, c) => sum + c.tetes, 0);
        console.log("[PENALITY DEBUG]", {
            takenRow: cartes.map(c => c.numero),
            bullHeads: cartes.map(c => c.tetes),
            totalPenalty: total
        });
        return total;
    }
}

// 4. Classe Table
class Table {
    constructor(deck) {
        this.rangs = [
            new Rang(deck.distribuer(1)[0]),
            new Rang(deck.distribuer(1)[0]),
            new Rang(deck.distribuer(1)[0]),
            new Rang(deck.distribuer(1)[0])
        ];
    }

    trouverBestRang(carte) {
        let bestIndex = -1;
        let minDiff = 105;

        for (let i = 0; i < this.rangs.length; i++) {
            let rang = this.rangs[i];
            let derniereCarte = rang.cartes[rang.cartes.length - 1];
            let diff = carte.numero - derniereCarte.numero;
            if (diff > 0 && diff < minDiff) {
                bestIndex = i;
                minDiff = diff;
            }
        }
        return bestIndex;
    }

    ajouterCarte(carte) {
        let bestRangIndex = this.trouverBestRang(carte);
        if (bestRangIndex !== -1) 
        {
            this.rangs[bestRangIndex].ajouterCarte(carte);
        } 
        else 
        {
            return -1;
        }
    }

    ramasserCartes() {
        for (let i = 0; i < this.rangs.length; i++) {
            if (this.rangs[i].estPleine()) {
                let cartesARamasser = this.rangs[i].recupererCartes();
                this.rangs[i] = new Rang(this.rangs[i].cartes[0]);
                return cartesARamasser;
            }
        }
        return [];
    }
}

// 5. Classe Hand
class Hand {
    constructor(cartes) {
        this.cartes = cartes;
    }

    trouverIndex(carte) {
        return this.cartes.findIndex(c => c.numero === carte.numero);
    }

    jouerCarte(index) {
        if (index < 0 || index >= this.cartes.length) throw new Error("Index invalide");
        return this.cartes.splice(index, 1)[0];
    }

    afficherHand() {
        return this.cartes;
    }
}

// 6. Classe Joueur
class Joueur {
    constructor(nom, deck, nb_cartes) {
        this.nom = nom;
        this.score = 0;
        this.hand = new Hand(deck.distribuer(nb_cartes));
        this.carteEnAttente ;    //on garde la carte joué en attendant que le joueur choississe un rang
    }

    updateScore(points) {
        this.score += points;
    }

    resetScore() {
        this.score = 0;
    }

    getHand() {
        return this.hand.cartes;
    }

    nouvelleMain(deck, nb_cartes) {
        this.hand = new Hand(deck.distribuer(nb_cartes));
    }

    trierCarte(){
        this.hand.cartes.sort((a, b) => a.numero - b.numero);
    }
}

// 7. Classe Jeu6Takes
class Jeu6Takes {
    constructor(nbJoueurs, nomJoueurs, nbMaxManches = 5, nbMaxHeads = 66, nbCarte = 10) {
        this.deck = new Deck(true);
        this.table = new Table(this.deck);
        this.nbMaxManches = nbMaxManches;
        this.nbMaxHeads = nbMaxHeads;
        this.nbCarte = nbCarte;
        this.nbJoueurs = nbJoueurs;
        this.mancheActuelle = 0;
        this.joueurs = nomJoueurs.map(nom => new Joueur(nom, this.deck, this.nbCarte));
    }

    checkEndManche() {
        return this.joueurs[0].hand.cartes.length === 0;
    }

    checkEndGame() {
        return this.joueurs.some(j => j.score >= this.nbMaxHeads) || this.mancheActuelle >= this.nbMaxManches;
    }

    mancheSuivante() {
        // this.mancheActuelle++;
        
        // Nouveau deck et nouvelle table
        this.deck = new Deck(true);
        this.table = new Table(this.deck);

        // Redonner une nouvelle main à chaque joueur
        for (let joueur of this.joueurs) {
            joueur.nouvelleMain(this.deck, this.nbCarte);
        }
    }
    
    resetGame() {
        this.deck = new Deck(true);
        this.table = new Table(this.deck);
        this.mancheActuelle = 0;
    
        this.joueurs.forEach(joueur => {
            joueur.hand = new Hand(this.deck.distribuer(this.nbCarte));
            joueur.resetScore();
        });
    
        console.log("Nouvelle partie");
    }
    
    

    jouerCarte(nomJoueur, carte) {

        const joueur = this.joueurs.find(j => j.nom === nomJoueur);
        if (!joueur) throw new Error("Joueur introuvable");

        const index = joueur.hand.trouverIndex(carte);
        if (index === -1) throw new Error("Carte non trouvée dans la main du joueur");

        joueur.hand.jouerCarte(index);
        const rang = this.table.ajouterCarte(carte);
        if(rang === -1)
        {
            //on attend que le joueurs choisisse un rang
            joueur.carteEnAttente = carte; // stocke la carte pour traitement ultérieur
            return {action: "choix_rang_obligatoire" , index: -1};
        }
        let index_rang;
        for (let i = 0; i < 4; i++) 
        {
            if(this.table.rangs[i].estPleine())
                index_rang = i;
        }

        // On ne prend que les 5 premières cartes de la rangée (sans la carte posée)
        const cartesRamassees = this.table.ramasserCartes();
        const penalite = Rang.calculerPenalite(cartesRamassees);
        joueur.updateScore(penalite);
        if(cartesRamassees.length >0)
        {
            return {action: "ramassage_rang" , index: index_rang};
        }

    }

    existeBot() {
        return this.joueurs.some(j => j.nom.startsWith("Bot"));
    }
      
    nbBots() {
    return this.joueurs.filter(j => j.nom.startsWith("Bot")).length;
    }
      
    
}

export { Jeu6Takes };
export { Joueur };
export { Carte };
export { Rang };