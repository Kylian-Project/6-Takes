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
const cartesAJouerParRoom = {}; // { roomId: [ { username, carte } ] }



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

	// Normalisation carte
	const carteJouee = typeof card === "number" ? { numero: card } : card;

	// Initialise la liste si besoin
	if (!cartesAJoueesParRoom[roomId]) cartesAJoueesParRoom[roomId] = [];


	cartesAJoueesParRoom[roomId].push({ username, carte: carteJouee });

	console.log(`🃏 ${username} a posé la carte ${carteJouee.numero}`);

	// Récupérer la room et la limite attendue
	const room = rooms.find(r => r.id === roomId);
	const limite = room?.settings?.playerLimit || jeu.joueurs.length;

	console.log("La limite est : ", limite);
	console.log("la comparaison est avec  :" , cartesAJoueesParRoom[roomId].length);
	//attente que tous les joueurs aient joué
	//ajouter un timer comme ca si on depasse les 45s par exemple ca sera une carte random qui sera joué
	if (cartesAJoueesParRoom[roomId].length === limite) 
	{
		const actions = cartesAJoueesParRoom[roomId];

		// Trier par ordre croissant
		actions.sort((a, b) => a.carte.numero - b.carte.numero);

		for (const { username, carte } of actions) {
		try {
			jeu.jouerCarte(username, carte);
			console.log(`✅ ${username} a joué ${carte.numero}`);
		} catch (err) {
			console.error(`❌ Erreur avec ${username} :`, err.message);
		}
		}

		//Maj de la table
		const table = jeu.table.rangs.map(r => r.cartes.map(c => c.numero));
		io.to(roomId).emit("update-table", table);
		console.log("📤 Table actuelle :", table);
		
		// Scores
		const scores = jeu.joueurs.map(j => ({ nom: j.nom, score: j.score }));
		io.to(roomId).emit("update-scores", scores);

		// Nettoyage pour prochain tour
		cartesAJoueesParRoom[roomId] = [];
	}
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
