import { rooms } from "./lobbies.js";
import { Jeu6Takes ,Joueur, Carte } from "../algo/6takesgame.js";

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

	socket.on("play-card", ({ roomId, card, username }) => {
		const jeu = getGame(roomId);
		if (!jeu) return console.log("❌ Partie introuvable :", roomId);
	  
		const carteJouee = typeof card === "number" ? { numero: card } : card;
		if (!cartesAJoueesParRoom[roomId]) cartesAJoueesParRoom[roomId] = [];
		cartesAJoueesParRoom[roomId].push({ username, carte: carteJouee });
	  
		console.log(`🃏 ${username} a posé la carte ${carteJouee.numero}`);
	  
		const room = rooms.find(r => r.id === roomId);
		const limite = room?.settings?.playerLimit || jeu.joueurs.length;
	  
		// Lancer le timer dès le premier joueur
		if (cartesAJoueesParRoom[roomId].length === 1 && !timers[roomId]) {
		  const tempsRestant = room?.settings?.roundTimer || 45;
		  timers[roomId] = setTimeout(() => {
			console.log(`⏰ Timer écoulé dans la room ${roomId}, on complète avec des cartes random`);
	  
			const dejaJoue = cartesAJoueesParRoom[roomId].map(p => p.username);//ayant deja jouée
			const absents = retrouverJoueursAbsents(roomId, dejaJoue);
	  
			for (const username of absents) {
			  const joueur = jeu.joueurs.find(j => j.nom === username);
			  if (!joueur || joueur.getHand().length === 0) continue;
	  
			  const numero =joueur.getHand()[0].numero;//1ere carte de la mauin du joueur
			  console.log(`🤖 ${username} a joué automatiquement la carte ${numero}`);
			  cartesAJoueesParRoom[roomId].push({ username, carte : {numero} });
			}
				const actions = cartesAJoueesParRoom[roomId];
				actions.sort((a, b) => a.carte.numero - b.carte.numero);
				
		  	for (const { username, carte } of actions) 
		  	{
				try 
				{
				const res = jeu.jouerCarte(username, carte);
		
					if (res === "CHOIX_RANGEE_NECESSAIRE") 
					{
						const joueur = jeu.joueurs.find(j => j.nom === username);
						joueur.carteEnAttente = carte;
			
						const rangsInfo = jeu.table.rangs.map((rang, i) => ({
						index: i,
						cartes: rang.cartes.map(c => c.numero),
						penalite: rang.totalTetes()
						}));
			
						const socketTarget = io.sockets.sockets.get(
						room.users.find(u => u.username === username).idSocketUser
						);
			
						socketTarget.emit("choix-rangee", { roomId, rangs: rangsInfo, username });
						return; // On arrête ici, on reprendra après le choix
					}
					console.log(`✅ ${username} a joué ${carte.numero}`);
				} 
				catch (err) 
				{
					console.error(`❌ Erreur avec ${username} :`, err.message);
				}
				const userSocketId = room.users.find(u => u.username === username)?.idSocketUser;

				const joueur = jeu.joueurs.find(j => j.nom === username);
				if (joueur && userSocketId) {
				  const nouvelleMain = joueur.getHand().map(c => c.numero);
				  console.log(`🎯 Main mise à jour de ${username} :`, nouvelleMain);
				  io.to(userSocketId).emit("your-hand", nouvelleMain);
				}
		  }

		  
			clearTimeout(timers[roomId]);
			delete timers[roomId];
			//traiterTour(roomId);
			const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
			console.log("🎯 Table mise à jour :", table);
			io.to(roomId).emit("update-table", table);
		
			const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score }));
			io.to(roomId).emit("update-scores", scores);
			io.to(roomId).emit("tour", { username });
			cartesAJoueesParRoom[roomId] = [];


  
		  }, tempsRestant * 1000);
		}
	  
		// Tous les joueurs ont joué
		if (cartesAJoueesParRoom[roomId].length === limite) {
		  clearTimeout(timers[roomId]);
		  delete timers[roomId];
		  //traiterTour(roomId);
		  const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
		  console.log("🎯 Table mise à jour :", table);
		  io.to(roomId).emit("update-table", table);
	  
		  const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score }));
		  io.to(roomId).emit("update-scores", scores);
		  io.to(roomId).emit("tour", { username });
		  cartesAJoueesParRoom[roomId] = [];


		}
	  });
	  

	  
  








	
	// 3. Choix d'une rangée si la carte est trop faible
	socket.on("choisir-rangee", ({ roomId, indexRangee, username }) => {
		const jeu = getGame(roomId);
		if (!jeu) return;
	  
		const joueur = jeu.joueurs.find(j => j.nom === username);
		if (!joueur || !joueur.carteEnAttente) return;
	  
		const carte = joueur.carteEnAttente;
		const cartesARamasser = jeu.table.rangs[indexRangee].recupererCartes();
		const penalite = cartesARamasser.reduce((sum, c) => sum + c.tetes, 0);
		joueur.updateScore(penalite);
	  
		jeu.table.rangs[indexRangee] = new Rang(carte);
		delete joueur.carteEnAttente;
	  
		// Mise à jour table et scores
		const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
		io.to(roomId).emit("update-table", table);
	  
		const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score }));
		io.to(roomId).emit("update-scores", scores);
	  
		console.log(`✅ ${joueur.nom} a choisi de ramasser la rangée ${indexRangee}`);
	  
		// 🧠 Optionnel : Tu pourrais ici rappeler la fin du tour si d'autres joueurs attendaient encore.
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




//fonction qui compare entre une liste de joueur ayant deja jouées et la liste des joueurs de la room 
//pour retrouver qui na pas encore jouer
function retrouverJoueursAbsents(roomId, joueursDejaJoue) {
	const jeu = getGame(roomId);
	const room = rooms.find(r => r.id === roomId);
	if (!jeu || !room) return [];
  
	const nomsAttendus = jeu.joueurs.map(j => j.nom);
	const absents = nomsAttendus.filter(nom => !joueursDejaJoue.includes(nom));
	return absents;
  }
  