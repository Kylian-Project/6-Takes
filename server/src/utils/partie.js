import {Server , socket } from "socket.io";
import { Jeu6Takes ,Joueur } from "../algo/6takesgame.js";
import { rooms } from "./lobbies.js";

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



////////////////////////////////Deroulemet du jeu


export const PlayGame = (socket, io) =>
{

  	socket.on("start-game", (roomId) => 
	{
		const usernames = getUsers(roomId);
		const usersWithSocket = getUsersAndSocketId(roomId);

		// Initialisation du jeu
		let bool= games.find(g => g.roomId === roomId);
		if(bool === undefined || bool.newGame === true)
		{
			jeu = new Jeu6Takes(usernames.length, usernames);
		}
		const jeu = new Jeu6Takes(usernames.length, usernames);
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




  	//////////////////////////////////////////////////
	// squellette a avoir en cours d'implementation //
  	//////////////////////////////////////////////////


	// 2. Jouer une carte
	socket.on("play-card", ({ roomId, card, username }) => {
	  // TODO
	});
  
	// 3. Choix d'une rangée si la carte est trop faible
	socket.on("choisir-rangee", ({ roomId, indexRangee, username }) => {
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
