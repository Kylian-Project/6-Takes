import { rooms } from "./lobbies.js";
import { Jeu6Takes ,Joueur, Carte, Rang } from "../algo/6takesgame.js";


class Game
{
	constructor(roomId, Jeu6Takes) 
	{
		this.roomId = roomId;
		this.Jeu = Jeu6Takes;
	}
}

function getUsers(roomId) 
{
	const room = rooms.find(r => r.id === roomId);
  	return room ? room.users.map(u => u.username) : [];
}

function getUsersAndSocketId(roomId)
{
  	const room = rooms.find(r => r.id === roomId);
  	return room ? room.users : [];
}

function getGame(roomId) 
{
  	const game = games.find(g => g.roomId === roomId);
  	return game ? game.Jeu : null;
}


const games = [];		// tableau de Game
const cartesAJoueesParRoom = {}; // { roomId: [ { username, carte } ] }
const timers = {};  // un timer par room
const affichageTimers = {};
const fileTraitementParRoom = {}; 
const joueursPretPourTour = {};


	  	//////////////////////////////////////////////////
		/////// Deroulement du jeu ///////////////////////
  		//////////////////////////////////////////////////

export const PlayGame = (socket, io) =>
{

	/***************************/
	/*      1.Start Game       */
	/***************************/
  	socket.on("start-game", (roomId) => 
	{
		const usernames = getUsers(roomId);
		const usersWithSocket = getUsersAndSocketId(roomId);

		const room = rooms.find(r => r.id === roomId);
		const settings = room.settings; // settings récupérés de la room

		// Initialisation du jeu
		let bool= games.find(g => g.roomId === roomId);
		let jeu;
		if (!bool) 
		{
		  	jeu = new Jeu6Takes(
				usernames.length,
				usernames,
				settings.rounds,
				settings.endByPoints,
				settings.numberOfCards
				);

		  games.push(new Game(roomId, jeu));
		} 
		else 
		{
		  jeu = bool.Jeu;
		}
		
		games.push({ roomId, Jeu: jeu });

		// On notify players que le jeu va commence
		io.to(roomId).emit("game-starting");

		// Distribution des cartes avec 2 secs de delay
		setTimeout(() => {
			for (let i = 0; i < usernames.length; i++) 
			{
				// On a déjà distribué les cartes dans le constructeur
				const joueur = jeu.joueurs[i];
				const socketId = usersWithSocket.find(u => u.username === joueur.nom)?.idSocketUser;

				if (socketId) {
					io.to(socketId).emit("your-hand", joueur.getHand().map(c => c.numero));
				}
			}
		},2000);

		// Envoi de la table initiale à tous sert pas a grand chose a RETIRER
		const tableInit = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
		io.to(roomId).emit("initial-table", tableInit);


		console.log(`✅ Partie lancée dans la room ${roomId} avec joueurs:`, usernames);
	
	});


	/***************************/
	/*     2. start-tour       */
	/***************************/

	socket.on("tour", ({ roomId, username }) => 
	{
		if (!joueursPretPourTour[roomId]) joueursPretPourTour[roomId] = [];
		
		if (!joueursPretPourTour[roomId].includes(username))
		{
			joueursPretPourTour[roomId].push(username);
		}
		
		const jeu = getGame(roomId);
		const room = rooms.find(r => r.id === roomId);
		
		if (!jeu || !room) return;
		const usernames = getUsers(roomId);
		
		const nombreBots = jeu.existeBot() ? jeu.nbBots() : 0;
		const joueursAttendus = usernames.length - nombreBots;
		  

		//on lance tour que si ils sont tous la 
		//histoire de tout factoriser a l'interieur de tour 
		//pour que ca soit plus clair que les event comme youh-hand, update-table...
		//sont tous envoyé en meme temps dan le "tour"
		if (joueursPretPourTour[roomId].length === joueursAttendus) 
		{
			console.log(`🚦 Tous les joueurs sont prêts, start - tour !`);		

			//faire jouer automatiquement les bots b1sur une fois que tous les joueurs sont prets
			jeu.joueurs.forEach(joueur => 
			{
				if (joueur.nom.startsWith("Bot") && joueur.getHand().length > 0) 
				{
					const carte = joueur.getHand()[0];
					console.log(`🤖 ${joueur.nom} a joué ${carte.numero}`);
					if (!cartesAJoueesParRoom[roomId]) cartesAJoueesParRoom[roomId] = [];
					cartesAJoueesParRoom[roomId].push({ username: joueur.nom, carte });
				}
			});

			lancerTimer(roomId, jeu, io, cartesAJoueesParRoom, rooms);

			// Envoi des mains et de la table
			envoyerMainEtTable(io, roomId, jeu, rooms);
		
			// Reset pour prochaine fois
			joueursPretPourTour[roomId] = [];
		}
	});


	/***************************/
	/*    3. Jouer une carte   */
	/***************************/
	socket.on("play-card", async ({ roomId, card, username }) =>
	{


		const jeu = getGame(roomId);
		if (!jeu) return ;
	  
		const carteJouee = typeof card === "number" ? { numero: card } : card;

		if (!cartesAJoueesParRoom[roomId]) cartesAJoueesParRoom[roomId] = [];
		cartesAJoueesParRoom[roomId].push({ username, carte: carteJouee });
	  
	  
		const room = rooms.find(r => r.id === roomId);	  
		console.log(`🃏 ${username} a posé la carte ${carteJouee.numero}`);

		const nombreBots = jeu.existeBot() ? jeu.nbBots() : 0;
		const usernames = getUsers(roomId);
		const joueursAttendus = usernames.length ;

		// Tous les joueurs ont joué pas de soucis de temps
		if (cartesAJoueesParRoom[roomId].length === joueursAttendus) 
		{
			clearTimeout(timers[roomId]);
			delete timers[roomId];
			clearInterval(affichageTimers[roomId]);
			delete affichageTimers[roomId];

			//pour traiter les cartes une par une on ajoute une file
			//on copie le contenu exct de CarteAJou dans fileTraitement
			fileTraitementParRoom[roomId] = [...cartesAJoueesParRoom[roomId]].sort((a, b) => a.carte.numero - b.carte.numero);
			cartesAJoueesParRoom[roomId] = [];

			await traiterProchaineCarte(roomId, jeu, io, rooms);

			lancerTimer(roomId, jeu, io, cartesAJoueesParRoom, rooms);
			
			//!!a factoriser	
			if(jeu.checkEndManche())
			{
				jeu.mancheActuelle++;
				if(!jeu.checkEndGame())
				{
					console.log("fin de manche");
					envoyerMainEtTable(io, roomId, jeu, rooms);	// avoir la table finale

					const classement = jeu.joueurs
					.map(j => ({ nom: j.nom, score: j.score }))
					.sort((a, b) => a.score - b.score); // tri cdes scores

					io.to(roomId).emit("score-manche",{classement});	//suggestion du prof!!!


					jeu.mancheSuivante();
					envoyerMainEtTable(io, roomId, jeu, rooms);	//on envoie la nouvelle table 
					io.to(roomId).emit("manche-suivante",jeu.mancheActuelle);
			
				}
				else 
				{
					const classement = jeu.joueurs
					.map(j => ({ nom: j.nom, score: j.score }))
					.sort((a, b) => a.score - b.score); // tri cdes scores

					console.log("🏁 Fin de partie");
					io.to(roomId).emit("end-game", { classement });

				}
			}
			else
			{
				notifierScore(io, roomId, jeu);	//prsq dans mes test apres reception de update score j'envoie drct "toue"
			}
		}

    });
         
	
	/***************************/
	/*    4. Choir une rangée  */
	/***************************/		
	socket.on("choisir-rangee", ({ roomId, indexRangee, username }) => 
	{
		handleChoixRangee(roomId, indexRangee, username, io);
	});
	
	  
	// 4. Restaurer le jeu si besoin
	socket.on("restore-game", ({ roomId, username }) => {
	});
  
	// 6. Nouvelle partie
	socket.on("new-game", (roomId) => {
	});
  
	// 7. Quitter la room volontairement
	socket.on("leave-room", (roomId) => {
	});
  
	// 8. Déconnexion (abandon ou fermeture de navigateur)
	socket.on("disconnect", () => {
	});

};




	//////////////////////////////////////////////////
	////////////// fonctions utilitaires /////////////
  	//////////////////////////////////////////////////



//fonction qui compare entre une liste de joueur ayant deja jouées et la liste des joueurs de la room 
//pour retrouver qui na pas encore jouer
function retrouverJoueursAbsents(roomId, joueursDejaJoue) 
{
	const jeu = getGame(roomId);
	const room = rooms.find(r => r.id === roomId);
	if (!jeu || !room) return [];
  
	const nomsAttendus = jeu.joueurs.map(j => j.nom);
	const absents = nomsAttendus.filter(nom => !joueursDejaJoue.includes(nom));
	return absents;
}
  

function notifierScore(io, roomId, jeu) 
{
	//quand le client recoit ceci cela veut dire qu'on peut passer au prochain tour
	const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score ?? 0 }));
	io.to(roomId).emit("update-scores", scores);
  
	cartesAJoueesParRoom[roomId] = [];
}
  
  

function jouerCartesAbsents(roomId, jeu, io, cartesAJoueesParRoom, rooms) 
{
	const room = rooms.find(r => r.id === roomId);
	if (!room || !jeu) return;

	const dejaJoue = (cartesAJoueesParRoom[roomId] || []).map(p => p.username);
	const absents = retrouverJoueursAbsents(roomId, dejaJoue);

	for (const username of absents) 
	{
		const joueur = jeu.joueurs.find(j => j.nom === username);
		if (!joueur || joueur.getHand().length === 0) continue;

		const carte = joueur.getHand()[0]; // Joue la première carte
		cartesAJoueesParRoom[roomId].push({ username, carte });

		console.log(`🤖 ${username} a joué automatiquement la carte ${carte.numero}`);
	}
}





function lancerTimer(roomId, jeu , io , cartesAJoueesParRoom, rooms)
{
	//comme ca meme si un event "tour" est recu on l'ignre si on a deja un timer pour la meme room
	if(timers[roomId])
	{
		return;		
	}
	const room = rooms.find(r => r.id === roomId);
	const duration = (room?.settings?.roundTimer || 45) * 1000;
	let secondesRestantes = duration/1000 ;
	console.log("le timer est lancé pour la room", roomId);

	timers[roomId] = setTimeout(() => 
	{
		console.log(`⏰ Timer écoulé pour room ${roomId}`);
		jouerCartesAbsents(roomId, jeu, io, cartesAJoueesParRoom, rooms);

        fileTraitementParRoom[roomId] = [...cartesAJoueesParRoom[roomId]].sort((a, b) => a.carte.numero - b.carte.numero);
        cartesAJoueesParRoom[roomId] = [];
        traiterProchaineCarte(roomId, jeu, io, rooms);
        

		delete timers[roomId];
		notifierScore(io, roomId, jeu);

		clearInterval(affichageTimers[roomId]);
		delete affichageTimers[roomId];

	}, duration);

	//envoyer le timer aux joueurs
	affichageTimers[roomId] = setInterval(() => {
		secondesRestantes--;

		io.to(roomId).emit("temps-room", secondesRestantes);
		if(secondesRestantes <= 0)
		{
			clearInterval(affichageTimers[roomId]);
			delete affichageTimers[roomId];
		}
	},1000);

  }


function handleChoixRangee(roomId, indexRangee, username, io) 
{
	const jeu = getGame(roomId);
	const room = rooms.find(r => r.id === roomId);
	if (!jeu || !room) return;

	const joueur = jeu.joueurs.find(j => j.nom === username);
	const carte = joueur?.carteEnAttente;
	if (!joueur || !carte) return;

	const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes_special_case();
	const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
	joueur.updateScore(penalite);
	let temp_carte = new Carte(carte.numero);
	jeu.table.rangs[indexRangee] = new Rang(temp_carte);
	delete joueur.carteEnAttente;
}








//fonction recursive pour traiter les cartes une apres l'autre ce qui permet une asychronie
//lors du traitement , utilise une file d’attente (fileTraitementParRoom[roomId]) pour
//traiter les cartes dans l’ordre croissant sans chevauchement


async function traiterProchaineCarte(roomId, jeu, io, rooms) 
{
    const file = fileTraitementParRoom[roomId];
    const room = rooms.find(r => r.id === roomId);
    if (!file || !file.length || !room) return;

    const { username, carte } = file.shift();

    try 
    {
        const res = jeu.jouerCarte(username, carte);
		
		if (res === "choix_rang_obligatoire") 
        {
            const joueur = jeu.joueurs.find(j => j.nom === username);
            joueur.carteEnAttente = carte;

            const rangsInfo = jeu.table.rangs.map((rang, i) => ({
                index: i,
                cartes: rang.cartes.map(c => c.numero),
                penalite: rang.totalTetes()	// a retirer prsq le joueur est sensé les calculer !!!!
            }));

			//on traite les cas separement pour eviter les bugs
			if(username.startsWith("Bot"))
			{
				io.to(roomId).emit("attente-choix-rangee", { username });
				await new Promise(resolve => setTimeout(resolve, 5000));
				const indexRangee = Math.floor(Math.random() * 4);
				const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes_special_case();
				const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
				joueur.updateScore(penalite);
				jeu.table.rangs[indexRangee] = new Rang(new Carte(carte.numero));
				delete joueur.carteEnAttente;
				traiterProchaineCarte(roomId, jeu, io, rooms);
			}

			else
			{
				const socketTargetId = room.users.find(u => u.username === username)?.idSocketUser;
				const socketTarget = io.sockets.sockets.get(socketTargetId);
				socketTarget.emit("choix-rangee", { roomId, rangs: rangsInfo, username });
				io.to(roomId).except(socketTargetId).emit("attente-choix-rangee", { username });

				await new Promise((resolve) => 
				{
					const handler = ({ roomId: rid, indexRangee, username: uname }) => 
					{
						if (rid === roomId && uname === username) 
						{
							clearTimeout(timeoutId); // annulation ici du timer
							socketTarget.off("choisir-rangee", handler);
							const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes_special_case();
							const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
							joueur.updateScore(penalite);
							jeu.table.rangs[indexRangee] = new Rang(new Carte(carte.numero));
							delete joueur.carteEnAttente;
							resolve();
							traiterProchaineCarte(roomId, jeu, io, rooms);
						}
					};
					
					//  Lancement écoute du choix
					socketTarget.on("choisir-rangee", handler);
					let timer=15;	// on laisse au joueur 15s pour choisir son rang

					//si rien recu pendant 15s alors on arrete l'ecoute et on choisit aléatoirement un rang
					const timeoutId = setTimeout(() =>  
					{
						socketTarget.off("choisir-rangee", handler); // Suppression de l'ecoute
						console.log(`⚠️ ${username} n'a pas choisi de rangée à temps, on choisit aléatoirement`);
					
						const indexRangee = Math.floor(Math.random() * 4);
						const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes_special_case();
						const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
						joueur.updateScore(penalite);
						jeu.table.rangs[indexRangee] = new Rang(new Carte(carte.numero));
						delete joueur.carteEnAttente;
						resolve();		//on arrete la promesse
					}, timer*1000);
				});
			}	  
        }


		//pour le cas de la 6eme carte
		else if (res=== "ramassage_rang")
		{
			const socketTargetId = room.users.find(u => u.username === username)?.idSocketUser;
			io.to(roomId).emit("ramassage_rang", { username });
		}


    }
    catch (err)
    {
        console.error(`❌ Erreur avec ${username} :`, err.message);
    }

    // Traiter la prochaine carte après celle-ci
    traiterProchaineCarte(roomId, jeu, io, rooms);

	//verifie si la game n'est pas finie 
	//si jamais ya pas eu de 'play-card' et que c'etais automatique
	//comme ca on est sur de faire un check end game meme si ya pas eu de 'play-card'
	if(jeu.checkEndManche())
		{
			jeu.mancheActuelle++;
			if(!jeu.checkEndGame())
			{
				console.log("fin de manche");
				envoyerMainEtTable(io, roomId, jeu, rooms);	// avoir la table finale

				const classement = jeu.joueurs
				.map(j => ({ nom: j.nom, score: j.score }))
				.sort((a, b) => a.score - b.score); // tri cdes scores

				io.to(roomId).emit("score-manche",{classement});	//suggestion du prof!!!


				jeu.mancheSuivante();
				envoyerMainEtTable(io, roomId, jeu, rooms);	//on envoie la nouvelle table 
				io.to(roomId).emit("manche-suivante",jeu.mancheActuelle);
		
			}
			else 
			{
				const classement = jeu.joueurs
				.map(j => ({ nom: j.nom, score: j.score }))
				.sort((a, b) => a.score - b.score); // tri cdes scores

				console.log("🏁 Fin de partie");
				io.to(roomId).emit("end-game", { classement });

			}
		}
}



function envoyerMainEtTable(io, roomId, jeu, rooms) 
{
	const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
	console.log("🎯 Table mise à jour :", table);
	io.to(roomId).emit("update-table", table);


	const room = rooms.find(r => r.id === roomId);

	if (!room) return;
	const usernames = getUsers(roomId);
	const usersWithSocket = getUsersAndSocketId(roomId);

	for (let i = 0; i < usernames.length; i++)
	{
		const joueur = jeu.joueurs[i];
		const socketId = usersWithSocket.find(u => u.username === joueur.nom)?.idSocketUser;
		if (socketId) 
		{
			io.to(socketId).emit("your-hand", joueur.getHand().map(c => c.numero));
			console.log(`🖐️ Main envoyée à ${joueur.nom}`);
		}
	}


}