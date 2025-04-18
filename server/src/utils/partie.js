import { rooms } from "./lobbies.js";
import { Jeu6Takes ,Joueur, Carte, Rang } from "../algo/6takesgame.js";

const NB_CARTES = 10;

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
// Mémoire temporaire pour stocker les cartes jouées par room
const cartesAJoueesParRoom = {}; // { roomId: [ { username, carte } ] }
const timers = {};  // un timer par room
const affichageTimers = {};
let verrou = true;



  	//////////////////////////////////////////////////
	/////////////// Deroulement du jeu ///////////////
  	//////////////////////////////////////////////////

export const PlayGame = (socket, io) =>
{

  	socket.on("start-game", (roomId) => 
	{
		const usernames = getUsers(roomId);
		const usersWithSocket = getUsersAndSocketId(roomId);

		// Initialisation du jeu
		let bool= games.find(g => g.roomId === roomId);
		let jeu;
		if (!bool) 
		{
		  jeu = new Jeu6Takes(usernames.length, usernames);
		  games.push(new Game(roomId, jeu));
		} 
		else 
		{
		  jeu = bool.Jeu;
		}
		
		games.push({ roomId, Jeu: jeu });

		// Distribution des cartes
		for (let i = 0; i < usernames.length; i++) 
		{
			// On a déjà distribué les cartes dans le constructeur
			const joueur = jeu.joueurs[i];
			const socketId = usersWithSocket.find(u => u.username === joueur.nom)?.idSocketUser;

			if (socketId) {
				io.to(socketId).emit("your-hand", joueur.getHand().map(c => c.numero));
			}
		}

		// Envoi de la table initiale à tous
		const tableInit = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
		io.to(roomId).emit("initial-table", tableInit);


		console.log(`✅ Partie lancée dans la room ${roomId} avec joueurs:`, usernames);
	
	});


	// 2. Jouer une carte

	socket.on("play-card", ({ roomId, card, username }) => 
	{


		const jeu = getGame(roomId);
		if (!jeu) return ;
	  
		const carteJouee = typeof card === "number" ? { numero: card } : card;

		if (!cartesAJoueesParRoom[roomId]) cartesAJoueesParRoom[roomId] = [];
		cartesAJoueesParRoom[roomId].push({ username, carte: carteJouee });
	  
	  
		const room = rooms.find(r => r.id === roomId);
		const limite = room?.settings?.playerLimit || jeu.joueurs.length;
	  
		console.log(`🃏 ${username} a posé la carte ${carteJouee.numero}`);

		// Tous les joueurs ont joué pas de soucis de temps
		if (cartesAJoueesParRoom[roomId].length === limite) 
		{
			console.log("time out deleted");

			clearTimeout(timers[roomId]);
			delete timers[roomId];
			
			clearInterval(affichageTimers[roomId]);
			delete affichageTimers[roomId];

			traiterCartesJouees(roomId, jeu, io, cartesAJoueesParRoom, rooms) ;
			notifierCarteJouee(io, roomId, jeu);

			//redemearrer le timer une fois que les joueurs ont tous jouées
			lancerTimer(roomId, jeu , io , cartesAJoueesParRoom, rooms);
		}
	});
	  

		// 2. JPasser au tour suivant -start-tour

	socket.on( "tour" , ({roomId, card , username }) =>
	{
		const jeu = getGame(roomId);
		if (!jeu)
			{ 
				console.log("evenement tour-start mais le jeu n'est pas lancé");
				return ;
			}
		cartesAJoueesParRoom[roomId] = [];
		lancerTimer(roomId, jeu , io , cartesAJoueesParRoom, rooms);
	});
  








	
	// 3. Choix d'une rangée si la carte est trop faible
	socket.on("choisir-rangee", ({ roomId, indexRangee, username }) => 
	{
		handleChoixRangee(roomId, indexRangee, username, io);
	});
	
	  
  







	// 4. Restaurer le jeu si besoin
	socket.on("restore-game", ({ roomId, username }) => {
	});
  
	// 5. Nouvelle manche
	socket.on("new-round", (roomId) => {
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
  

function notifierCarteJouee(io, roomId, jeu) 
{
	const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
	console.log("🎯 Table mise à jour :", table);
	io.to(roomId).emit("update-table", table);
  
	const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score ?? 0 }));
	io.to(roomId).emit("update-scores", scores);
  
	//const joueurSuivant = jeu.joueurs.find(j => !j.carteEnAttente); // par défaut
	//io.to(roomId).emit("tour", { username: joueurSuivant?.nom || null });
  
	cartesAJoueesParRoom[roomId] = [];
}
  

function notifierMain(io,socketId, joueur) 
{
	const nouvelleMain = joueur.getHand().map(c => c.numero);
	io.to(socketId).emit("your-hand", nouvelleMain);
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

		// Envoyer main à jour
		const userSocketId = room.users.find(u => u.username === username)?.idSocketUser;
		if (userSocketId) {
			io.to(userSocketId).emit("your-hand", joueur.getHand().map(c => c.numero));
		}
	}
}


async function traiterCartesJouees(roomId, jeu, io, cartesAJoueesParRoom, rooms) 
{
	const actions = cartesAJoueesParRoom[roomId];
	const room = rooms.find(r => r.id === roomId);
	if (!room || !actions) return;

	// Trier par valeur croissante
	actions.sort((a, b) => a.carte.numero - b.carte.numero);

	for (const { username, carte } of actions) {
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
					penalite: rang.totalTetes()
				}));
			
				const socketTargetId = room.users.find(u => u.username === username)?.idSocketUser;
				const socketTarget = io.sockets.sockets.get(socketTargetId);
				// Envoyer uniquement au joueur concerné
				if (socketTarget)
				{
					socketTarget.emit("choix-rangee", { roomId, rangs: rangsInfo, username });
				}
				
				await waitForVerrouRelease();
				
				// Envoyer à tous les autres joueurs de la room sauf lui
				if (socketTargetId) 
				{
					io.to(roomId).except(socketTargetId).emit("attente-choix-rangee", { username });
				}

				console.log("carte a traité differemnt");

				// Attendre que le joueur choisit une rangée

				//await sleep(40*1000);
				console.log("reprise du traitement des cartes");

			
				
				//return; // on stoppe ici, on reprendra après la réponse
			}

			console.log(`✅ ${username} a joué ${carte.numero}`);
		}
		catch (err) {
			console.error(`❌ Erreur avec ${username} :`, err.message);
		}

		// Notifier la nouvelle main du joueur
		const userSocketId = room.users.find(u => u.username === username)?.idSocketUser;
		const joueur = jeu.joueurs.find(j => j.nom === username);
		if (joueur && userSocketId)
		{
			notifierMain(io, userSocketId, joueur);
		}
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
		traiterCartesJouees(roomId, jeu, io, cartesAJoueesParRoom, rooms) ;
		delete timers[roomId];
		notifierCarteJouee(io, roomId, jeu);

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

	const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes();
	const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
	joueur.updateScore(penalite);
	let temp_carte = new Carte(carte.numero);
	jeu.table.rangs[indexRangee] = new Rang(temp_carte);
	delete joueur.carteEnAttente;

	verrou = false;

}



function sleep(ms) 
{
	return new Promise(resolve => setTimeout(resolve, ms));
}



function waitForVerrouRelease(timeout = 30000) {
    return new Promise(resolve => {
        const interval = setInterval(() => {
            if (!verrou) {
                clearInterval(interval);
                resolve();
            }
        }, 100);

        setTimeout(() => {
            if (verrou) {
                console.log("⏰ Timeout de verrou, reprise forcée");
                verrou = false;
                clearInterval(interval);
                resolve();
            }
        }, timeout);
    });
}
