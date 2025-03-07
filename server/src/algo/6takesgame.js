//1. Classe Carte (Représente une carte avec sa valeur et ses têtes de clown)
// valeur == id de la carte
class Carte {
    constructor(numero) {
        this.numero = numero;
        this.tetes = this.calculerTetes();
    }

    calculerTetes() {
        if (this.numero === 55) return 7;  // Seul 55 a 7 tetes de clown
        if (this.numero % 11 === 0) return 5;
        if (this.numero % 10 === 0) return 3;
        if (this.numero % 5 === 0) return 2;
        return 1;
    }

    get carteId(){
        return this.numero;
    }
}   

//2. Classe Deck (Paquet de 104 cartes)
class Deck {
    constructor(empty = true) {
        if (typeof empty !== "boolean") {
            throw new Error("Invalid argument type: must be a boolean !");
        }
        
        this.cartes = [];
        if (empty) {
            for (let i = 1; i <= 104; i++) {
                this.cartes.push(new Carte(i));
            }
            this.melanger();
        } 
    }

    // melange de la fonction avec l'algo Fisher-Yates
    melanger() {
        for (let i = this.cartes.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [this.cartes[i], this.cartes[j]] = [this.cartes[j], this.cartes[i]];
        }
    }

    // distribution des n cartes a chaque joueur
    distribuer(n) {
        return this.cartes.splice(0, n); 
    }
}

//3. Classe Rang (Une rangée sur la table)
class Rang {
    constructor() {
        this.cartes = [];
    }

    ajouterCarte(carte) {
        this.cartes.push(carte);
    }

    estPleine() {
        return this.cartes.length === 6;
    }

    recupererCartes() {
        return this.cartes.splice(0, this.cartes.length - 1);
    }
}

//4. Classe Table (Gère les 4 rangées)
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
        let bestRang = null;
        let minDiff = 105;    // Plus grand que n'importe quel écart possible (104 max)

        for (let rang of this.rangs) {
            let derniereCarte = rang.cartes[rang.cartes.length - 1];
            let diff = carte.valeur - derniereCarte.valeur;
            if (diff > 0 && diff < minDiff) {
                bestRang = rang;
                minDiff = diff;
            }
        }
        return bestRang;
    }
}

//5. Classe Hand (Cartes en Hand d'un joueur)
class Hand {
    constructor(cartes) {
        this.cartes = cartes;
    }

    /*
    afficherCartes() {
        return this.cartes.map((carte, index) => `[${index}] Carte: ${carte.numero}, Têtes: ${carte.tetes}`).join("\n");
    }
    */

    jouerCarte(index) {
        if (index < 0 || index >= this.cartes.length) {
            throw new Error("Index invalide");
        }
        return this.cartes.splice(index, 1)[0];
    }
}


//6. Classe Joueur (Gestion des joueurs)
class Joueur {
    constructor(nom, deck, n) {
        this.nom = nom;
        this.Hand = new Hand(deck.distribuer(n));
        this.score = 0;
        //this.nbAFK = 0; Fonctionnalite a voir, pour une punition dun timer specifique apres une deconnexion(AFK)
        // plus le nombre est increment plus la punition(timer) soit eleve, pour quil puisse jouer son procahin jeu
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

    /*
    updateAfk() {
        this.nbAfk++;
    }

    resetAfk() {
        this.nbAfk = 0;
    }
    */
    
}

//7. Classe Jeu6Takes (Gestion du jeu complet)
class Jeu6Takes {
    constructor(nbJoueurs, nbMaxManches, nbMaxHeads) {
        this.deck = new Deck();
        this.table = new Table(this.deck);
        this.nbJoueurs = nbJoueurs;
        this.nbMaxManches = nbMaxManches;
        this.nbMaxHeads = nbMaxHeads;
        this.joueurs = [];
        
    }

    // A Completer
    









}