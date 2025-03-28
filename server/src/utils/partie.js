import { Jeu6Takes } from "../algo/6takesgame.js";
import { rooms } from "./lobbies.js";

const NB_CARTES = 10;
const games = []; // [{ roomId, Jeu: instanceDeJeu }]

function getUsers(roomId) {
  const room = rooms.find(r => r.id === roomId);
  return room ? room.users.map(u => u.username) : [];
}

function getUsersAndSocketId(roomId) {
  const room = rooms.find(r => r.id === roomId);
  return room ? room.users : [];
}

function getGame(roomId) {
  const game = games.find(g => g.roomId === roomId);
  return game ? game.Jeu : null;
}

export const PlayGame = (socket, io) => {

  socket.on("start-game", (roomId) => {
    const usernames = getUsers(roomId);
    const usersWithSocket = getUsersAndSocketId(roomId);

    // Initialisation du jeu
    const jeu = new Jeu6Takes(usernames.length, usernames);
    games.push({ roomId, Jeu: jeu });

    // Distribution des cartes
    for (let i = 0; i < usernames.length; i++) {
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

};
