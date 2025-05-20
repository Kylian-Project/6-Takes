import { rooms } from "./lobbies.js";
import { Jeu6Takes ,Joueur, Carte, Rang } from "../algo/6takesgame.js";
import Player from "../models/player.js";
import sequelize from "../config/db.js"

class Game
{
	constructor(roomId, Jeu6Takes) 
	{
		this.roomId = roomId;
		this.Jeu = Jeu6Takes;
	}
}

/**
 * recevoir la liste des joueurs dans une room specefique
 * 
 * @param {string} roomId
 * @returns {string[]}
 * 
*/

function getUsers(roomId) 
{
	const room = rooms.find(r => r.id === roomId);
  	return room ? room.users.map(u => u.username) : [];
}

/**
 * recevoir la liste des joueurs dans une room specefique et leur socket
 * 
 * @param {string} roomId 
 * @returns {{username: string, idSocketUser: string}[]}
 */
function getUsersAndSocketId(roomId)
{
  	const room = rooms.find(r => r.id === roomId);
  	return room ? room.users : [];
}


/**
 * recevoir l'instance de Jeu6Takes d'une room
 * 
 * @param {string} roomId
 * @returns {Jeu6Takes|null}
 */
function getGame(roomId) 
{
  	const game = games.find(g => g.roomId === roomId);
  	return game ? game.Jeu : null;
}


const games = [];		// tableau de Game
const cartesAJoueesParRoom = {}; // { roomId: [ { username, carte } ] }
export const timers = {};  // un timer par room
const affichageTimers = {};
const fileTraitementParRoom = {}; 
const joueursPretPourTour = {};
const carte_animation =  {};

	  	//////////////////////////////////////////////////
		/////// Deroulement du jeu ///////////////////////
  		//////////////////////////////////////////////////

/**
 * Gère le flux de jeu pour une salle en utilisant les événements Socket.IO
 * 
 *	La fonction écoute plusieurs événements, notamment :
 *	"start-game" : Initialise une instance de jeu pour la salle, notifie les joueurs et distribue les mains initiales.
 *	"tour" : Prépare la salle pour un nouveau tour, vérifie la disponibilité des joueurs et gère les actions des bots.
 *	"play-card" : Gère les actions de jeu de cartes, gère les minuteries et traite les cartes jouées.
 *	"choisir-rangee" : Gère la sélection des rangées par les joueurs.
 *	"restore-game", "new-game", "leave-room" et "disconnect" pour des tâches de gestion de jeu supplémentaires.
 * 
 * @param {Socket} socket - L'instance de socket Socket.IO pour le client connecté.
 * @param {SocketIO.Server} io - L'instance de serveur Socket.IO pour émettre des événements aux clients.
 */

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
		room.visibility = false;
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

		// On notifie players que le jeu va commencer
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

		//const nombreBots = jeu.existeBot() ? jeu.nbBots() : 0;
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

			//on copie le contenu exct de CarteAJouée dans carte_animation pour pouvoir l'envoyer au client pour l'animation
			carte_animation[roomId] = [];
			carte_animation[roomId] = cartesAJoueesParRoom[roomId];

			await traiterProchaineCarte(roomId, jeu, io, rooms);

			lancerTimer(roomId, jeu, io, cartesAJoueesParRoom, rooms);
			
			notifierScore(io, roomId, jeu);	//prsq dans mes test apres reception de update score j'envoie drct "toue"
		}

    });
         
	
	/***************************/
	/*    4. Choir une rangée  */
	/***************************/		
	socket.on("choisir-rangee", ({ roomId, indexRangee, username }) => 
	{
		handleChoixRangee(roomId, indexRangee, username, io);
	});


	/***************************/
	/*    5. trier les cartes  */
	/***************************/
	socket.on("sort-cards", ({ roomId, username }) => 
	{
		const jeu = getGame(roomId);
		let joueur = jeu.joueurs.find(j => j.nom === username);
		joueur.trierCarte();
		socket.emit("sorted-cards", joueur.getHand().map(c => c.numero));
	});


	/***************************/
	/*  6. rejouer une partie  */
	/***************************/
	socket.on("restart-game", (roomId) => 
	{
		// On notifie players que le jeu va commencer
		io.to(roomId).emit("game-starting");
		const jeu = getGame(roomId);
		jeu.resetGame();
		envoyerMainEtTable(io, roomId, jeu, rooms);
	})




	/***************************/
	/*  7. quitter une partie  */
	/***************************/

	socket.on("leave-room-in-game", async ({ roomId, username }) => 
	{
		console.log(`🚪 ${username} quitte la partie en cours dans la room ${roomId}`);
	
		const jeu = getGame(roomId);

		const joueur = jeu.joueurs.find(j => j.nom === username);
		if (!joueur) return console.error(`❌ Joueur ${username} introuvable`);
	
		// Ajouter en base de données

		const player = await Player.findOne({ where: { username: joueur.nom } });
		if (player) 
		{
			await issueBan(player.id);
			console.log(`🚫 Ban enregistré pour le joueur : ${username}`);
		}

		const botName = 'Bot' + Math.floor(Math.random() * 1000);
		joueur.nom = botName; // Mettre à jour le nom du joueur avec le nom du bot
		rooms.find(r => r.id === roomId).users.find(u => u.username === username).username = botName;
		io.to(roomId).emit("bot-replaced", { username, botName });
		console.log("Le joueur est remplacer par un bot", botName);
		// // Supprimer le joueur de la room et de la partie
		// const room = rooms.find(r => r.id === roomId);
		// if (room)
		// {
		// 	room.removeUser(socket.id);
		// 	socket.leave(roomId);
		// 	console.log(`✅ ${username} a quitté la room ${roomId}`);
		// 	io.to(roomId).emit("user-left", { username });
		// }
	});





}





	//////////////////////////////////////////////////
	////////////// fonctions utilitaires /////////////
  	//////////////////////////////////////////////////



/**
 * Retourne la liste des joueurs qui n'ont pas encore jouées dans la room.
 * compare entre une liste de joueur ayant deja jouées et la liste des joueurs de la room 
 * 
 * @param {string} roomId - ID de la room.
 * @param {string[]} joueursDejaJoue - Liste des joueurs qui ont deja jouer.
 * @returns {string[]} La liste des joueurs qui n'ont pas encore jouer.
 */
function retrouverJoueursAbsents(roomId, joueursDejaJoue) 
{
	const jeu = getGame(roomId);
	const room = rooms.find(r => r.id === roomId);
	if (!jeu || !room) return [];
  
	const nomsAttendus = jeu.joueurs.map(j => j.nom);
	const absents = nomsAttendus.filter(nom => !joueursDejaJoue.includes(nom));
	return absents;
}
  


/**
 * Notifie les joueurs d'une room de la mise à jour des scores.
 * Envoie un tableau de scores, chaque élément contenant le nom du joueur et son score.
 * Réinitialise également la liste cartesAJoueesParRoom[roomId] pour la prochaine ronde.
 * 
 * @param {SocketIO.Server} io - Instance du serveur Socket.IO pour l'émission d'événements.
 * @param {string} roomId - ID de la room pour laquelle les scores sont notifiés.
 * @param {Jeu6Takes} jeu - Instance du jeu en cours.
 */
function notifierScore(io, roomId, jeu) 
{
	//quand le client recoit ceci cela veut dire qu'on peut passer au prochain tour
	const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score ?? 0 }));
	io.to(roomId).emit("update-scores", scores);
  
	cartesAJoueesParRoom[roomId] = [];
}
  
  


/**
 * Fait jouer automatiquement les cartes des joueurs qui n'ont pas encore joué dans la room.
 * Fait cela en jouant la première carte de leur main.
 * @param {string} roomId - ID de la room.
 * @param {Jeu6Takes} jeu - Instance du jeu en cours.
 * @param {SocketIO.Server} io - Instance du serveur Socket.IO pour l'émission d'événements.
 * @param {Object} cartesAJoueesParRoom - Cartes jouées par salle.
 * @param {Room[]} rooms - Liste des salles disponibles.
 */
function jouerCartesAbsents(roomId, jeu, io, cartesAJoueesParRoom, rooms) 
{
	const room = rooms.find(r => r.id === roomId);
	if (!room || !jeu) return;

	const dejaJoue = (cartesAJoueesParRoom[roomId] || []).map(p => p.username);
	const absents = retrouverJoueursAbsents(roomId, dejaJoue);
	console.log("absents", absents);

	for (const username of absents) 
	{
		const joueur = jeu.joueurs.find(j => j.nom === username);
		if (!joueur || joueur.getHand().length === 0) continue;		

		const indexCarte = Math.floor(Math.random() * joueur.getHand().length);
		const carte = joueur.getHand()[indexCarte];
		//const carte = joueur.getHand()[0]; // Joue la première carte !!
		cartesAJoueesParRoom[roomId].push({ username, carte });

		console.log(`🤖 ${username} a joué automatiquement la carte ${carte.numero}`);
	}
}




/**
 * Lance un timer pour une salle de jeu,juste apres reception de 'tour' par tous les joueurs de la room .
 * 
 * Si un timer est déjà en cours pour la même salle, il ne fera rien.
 * définie dans les paramètres de la salle (par défaut 45 secondes).
 * 
 * Lors de l'expiration du timer, les cartes des joueurs absents sont jouées automatiquement,
 * les cartes sont triées et traitées séquentiellement, et les scores sont notifiés.
 * 
 * Le temps restant est émis à la salle chaque seconde pour mise à jour des joueurs.
 * 
 * @param {string} roomId - ID de la salle pour laquelle le timer est lancé.
 * @param {Jeu6Takes} jeu - Instance du jeu en cours.
 * @param {SocketIO.Server} io - Instance du serveur Socket.IO pour l'émission d'événements.
 * @param {Object} cartesAJoueesParRoom - Cartes jouées par salle.
 * @param {Room[]} rooms - Liste des salles disponibles.
 */



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

	timers[roomId] = setTimeout(async () => 
	{
		console.log(`⏰ Timer écoulé pour room ${roomId}`);
		jouerCartesAbsents(roomId, jeu, io, cartesAJoueesParRoom, rooms);

        fileTraitementParRoom[roomId] = [...cartesAJoueesParRoom[roomId]].sort((a, b) => a.carte.numero - b.carte.numero);

		//on copie le contenu exct de CarteAJouée dans carte_animation pour pouvoir l'envoyer au client pour l'animation
		carte_animation[roomId] = [];
		carte_animation[roomId] = cartesAJoueesParRoom[roomId];

        cartesAJoueesParRoom[roomId] = [];
        await traiterProchaineCarte(roomId, jeu, io, rooms);
        

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



/**
 * gere le choix d'une rangee par un joueur
 * 
 * @param {string} roomId - The ID of the room where the game is taking place.
 * @param {number} indexRangee - The index of the row chosen by the player.
 * @param {string} username - The username of the player making the choice.
 * @param {SocketIO.Server} io - The Socket.IO server instance for communication.
 */

function handleChoixRangee(roomId, indexRangee, username, io) 
{
	const jeu = getGame(roomId);
	const room = rooms.find(r => r.id === roomId);
	if (!jeu || !room) return;

	const joueur = jeu.joueurs.find(j => j.nom === username);
	const carte = joueur?.carteEnAttente;
	if (!joueur || !carte) return;

	// On récupère une COPIE des cartes à pénaliser AVANT de remplacer la rangée
	const cartesARamasser = [...jeu.table.rangs[indexRangee].cartes];
	const penalite = Rang.calculerPenalite(cartesARamasser); // Log debug
	joueur.updateScore(penalite);
	// On remplace la rangée par une nouvelle contenant uniquement la carte du joueur
	jeu.table.rangs[indexRangee] = new Rang(new Carte(carte.numero));
	delete joueur.carteEnAttente;
}








//fonction recursive pour traiter les cartes une apres l'autre ce qui permet une asychronie
//lors du traitement , utilise une file d’attente (fileTraitementParRoom[roomId]) pour
//traiter les cartes dans l’ordre croissant sans chevauchement


/**
 * Traite la prochaine carte de la file d'attente fileTraitementParRoom[roomId]
 * @param {Jeu6Takes} jeu - Jeu en cours
 * @param {SocketIO.Server} io - Serveur Socket.IO
 * @param {Room[]} rooms - Tableau des rooms
 * 
 */

async function traiterProchaineCarte(roomId, jeu, io, rooms) 
{
    const file = fileTraitementParRoom[roomId];

    const room = rooms.find(r => r.id === roomId);
    if (!file || !file.length || !room) return;

    const { username, carte } = file.shift();

    try 
    {
        const res = jeu.jouerCarte(username, carte);
		
		if (res.action === "choix_rang_obligatoire" && res.index === -1) 
        {
			console.log(" ⚠️⚠️ choix rang obligatoire");
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
				handleChoixRangee(roomId, indexRangee, username, io);
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
							clearTimeout(timeoutId);
							socketTarget.off("choisir-rangee", handler);
							handleChoixRangee(roomId, indexRangee, username, io);
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
						handleChoixRangee(roomId, indexRangee, username, io);
						resolve();		//on arrete la promesse
					}, timer*1000);
				});
			}
        }
		//pour le cas de la 6eme carte
		else if (res.action=== "ramassage_rang")
		{
			io.to(roomId).emit("ramassage-rang", { username , index:res.index });
		}

    }
    catch (err)
    {
        console.error(`❌ Erreur avec ${username} :`, err.message);
    }

    // Traiter la prochaine carte après celle-ci
    traiterProchaineCarte(roomId, jeu, io, rooms);

	//vérifie si la game n'est pas finie 
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

			io.to(roomId).emit("score-manche",{classement});//suggestion du prof!!!

			jeu.mancheSuivante();
			envoyerMainEtTable(io, roomId, jeu, rooms);	//on envoie la nouvelle table 
			io.to(roomId).emit("manche-suivante",jeu.mancheActuelle);
	
		}
		else
		{
			const classement = jeu.joueurs
			.map(j => ({ nom: j.nom, score: j.score }))
			.sort((a, b) => a.score - b.score); // tri cdes scores
			if(! username.startsWith("Bot"))
			{
				console.log("🏁 Fin de partie");
				envoyerMainEtTable(io, roomId, jeu, rooms);	///!!!
				io.to(roomId).emit("end-game", { classement });
				let room = rooms.find(r => r.id === roomId);
				if (!room) return;
				rooms = rooms.filter(r => r.id !== roomId);
			}
		}
	}
}



/**
 * Envoie la table et la main de chaque joueur individuellement
 * @param {SocketIO.Server} io
 * @param {string} roomId
 * @param {Jeu6Takes} jeu
 * @param {Room[]} rooms
 * 
 * @return la table et les mains
 */
function envoyerMainEtTable(io, roomId, jeu, rooms) 
{
	//les cartes jouées par salle poru faire l'animation
	console.log("cartes jouees", carte_animation[roomId]);
	io.to(roomId).emit("cartes-jouees", carte_animation[roomId]);
	carte_animation[roomId] = [];

	//puis envoie de la nouvelle table et de la nouvelle main (aprs retrait de la carte )
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



/**
 * Enregistre un ban pour l'ID du joueur fourni.
 * La fonction effectue une requête SQL pour appeler la procédure stockée `apply_ban` qui
 * met à jour la table `Player` pour indiquer que le joueur est banni.
 * Si la requête aboutit, un message est affiché indiquant que le ban a été enregistré.
 * Si une erreur survient, un message d'erreur est affiché.
 * @param {number} playerId - L'ID du joueur à bannir.
 */

async function issueBan(playerId) 
{
    try 
	{
		console.log(`🔄 Mise à jour du ban pour l'ID du joueur : ${playerId}`);
		await sequelize.query(`CALL apply_ban(${playerId})`);
        
        console.log(`🚫 Ban enregistré pour l'ID du joueur : ${playerId}`);
    } 
	catch (err)
	{
        console.error(`Erreur lors de l'application du ban : ${err.message}`);
    }
}
