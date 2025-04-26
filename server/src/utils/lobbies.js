import { Server } from "socket.io";
import randomstring from "randomstring";
import Lobby from "../models/lobbies.js"; // <-- Le modèle Sequelize
import Player from "../models/player.js"


const ID_LENGTH = 4;

class RoomUser {
    constructor(username, idSocketUser) {
    this.username = username;
    this.idSocketUser = idSocketUser;
  }
}

class Room {
    /**
     * Crée une instance de Room.
     * @param {string} id - ID unique de la room
     * @param {string} host - Nom de l'hôte (celui qui crée la room)
     * @param {string} idSocketHost - ID Socket.IO de l'hôte
     * @param {boolean} isPrivate - Si la room est privée (true) ou publique (false)
     * @param {object} [settings={}] - Paramètres de la room
     * @param {number} [settings.playerLimit=10] - Nombre maximum de joueurs
     * @param {number} [settings.numberOfCards=10] - Nombre de cartes distribuées
     * @param {number} [settings.roundTimer=45] - Temps (en secondes) pour jouer une carte
     * @param {number} [settings.endByPoints=66] - Nombre de points pour gagner
     * @param {number} [settings.rounds=3] - Nombre de tours
     * @param {string} [settings.lobbyName="Lobby"] - Nom de la room
     */
    constructor(id, host, idSocketHost, isPrivate, settings = {}) 
    {
        this.id = id;
        this.host = host;
        this.idSocketHost = idSocketHost;
        this.users = [];
        this.private = isPrivate;
        this.settings = {
            playerLimit: settings.playerLimit || 10,        //valeurs assignées par defaut
            numberOfCards: settings.numberOfCards || 10,
            roundTimer: settings.roundTimer || 45,
            endByPoints: settings.endByPoints || 66,
            rounds: settings.rounds || 3,
            lobbyName: settings.lobbyName || "Lobby"
        };
    }
  
    addUser(username, idSocketUser) {
        this.users.push(new RoomUser(username, idSocketUser));
    }
  
    removeUser(idSocketUser) {
        this.users = this.users.filter(user => user.idSocketUser !== idSocketUser);
    }
  
    getUsernames() {
        return this.users.map(user => user.username);
    }
  
    isFull() {
        return this.users.length >= this.settings.playerLimit; 
    }
    /*a voir par la suite si j'utilise ou pas
    async save() 
    {
        try 
        {
            const lobby = await Lobby.create({
                id: this.id,
                name: this.settings.lobbyName,
                state: this.private ? "PRIVATE" : "PUBLIC",
                playerLimit: this.settings.playerLimit,
                numberOfCards: this.settings.numberOfCards,
                roundTimer: this.settings.roundTimer,
                endByPoints: this.settings.endByPoints,
                rounds: this.settings.rounds
            });
            console.log(`Room ${this.id} saved in database`);
        } 
        catch (error) 
        {
            console.log(`Error saving room ${this.id} in database: ${error}`);
        }
    }*/
  }
  

export let rooms = [];




/**
 * Gère la logique de gestion des salles sur un serveur socket.io.
 * Cela inclut la création, la jonction et la sortie des salles, ainsi que
 * la diffusion d'événements de salle et la gestion de la disponibilité des salles.
 * 
 * @param {Socket} socket - L'objet socket pour le client connecté.
 * @param {Server} io - L'instance du serveur socket.io pour la diffusion d'événements.
 */
export const roomHandler = (socket, io) => 
{
    
         
    //////////////////////////////////////////////////
	////////////// fonctions principales /////////////
  	//////////////////////////////////////////////////

    const createRoom = async (rawData) => 
    {
        //on parse le string en JSON
        let data;
        try 
        {
            data = typeof rawData === "string" ? JSON.parse(rawData) : rawData;
        } 
        catch (err)
        {
            console.error("Erreur JSON parsing :", err.message);
            return;
        }
        //dé-structuration de l'objet en des variables
        const 
        {
            username = "Anonyme",       //TODO : a recuperer de la bdd une fois la liaison faite avec login 
            lobbyName = "",
            playerLimit = 10,
            numberOfCards = 10,
            roundTimer = 45,
            endByPoints = 66,
            rounds = 1,
            isPrivate = "PRIVATE" // Valeur par défaut
        } = data;

        const roomId = randomstring.generate({ length: ID_LENGTH, charset: "alphanumeric" });
        const isPrivateBool = isPrivate === "PRIVATE";  // Convertir la valeur de isPrivate en booleen

        const newRoom = new Room(roomId, username, socket.id, isPrivateBool , data);
        let playerID = await getPlayerID(username);
        
        newRoom.addUser(username, socket.id);
        rooms.push(newRoom);

        try {
            await Lobby.create({
            id_creator: playerID,
            name: roomId,
            state: isPrivate
            });
            console.log("✅ Room enregistrée en BDD :", roomId);
        } catch (err) {
            console.error("Erreur BDD :", err.message);
        }

        socket.join(roomId);
        io.emit("available-rooms", getAvailableRooms());
        socket.emit(isPrivateBool ? "private-room-created" : "public-room-created", roomId);
    };

    /**
     * Supprime une room et emet des événements pour que les utilisateurs
     * quittent la room.
     * @param {string} roomId - ID de la room à supprimer
     */
    const removeRoom = (roomId) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) return;
        rooms = rooms.filter(r => r.id !== roomId);
        if (room.private) 
        {
            io.to(roomId).emit("remove-private-room");  //pour tout les membres
        } 
        else 
        {
            io.to(roomId).emit("remove-public-room");
        }
        io.emit("available-rooms", getAvailableRooms());
    };

    /**
     * Permet à un utilisateur de rejoindre une room existante.
     * Émet un événement si la room est introuvable ou pleine.
     * @param {object} data - Informations nécessaires pour rejoindre la room
     * @param {string} data.roomId - ID de la room à rejoindre
     * @param {string} data.username - Nom d'utilisateur de la personne rejoignant la room
     * @returns {object|boolean} - Retourne la room si l'utilisateur a réussi à rejoindre, sinon retourne false
     */

    const joinRoom = ({ roomId, username }) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) 
        {
            socket.emit("room-not-found");
            return false;
        }
        if (room.isFull()) 
        {
            return false;
        }
        room.addUser(username, socket.id);
        return room;
    };

    /**
     * Fait quitter une room à un utilisateur.
     * Si l'utilisateur est l'hôte, supprime la room.
     * @param {object} data - Informations de la room à quitter
     * @param {string} data.roomId - ID de la room à quitter
     */
    const leaveRoom = ({ roomId }) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) return;
        const isHost = room.idSocketHost === socket.id;
        if (isHost) 
        {
            removeRoom(roomId);
            socket.to(roomId).emit("remove-room");
            socket.leave(roomId);
            socket.emit("room-left");
            return;
        }
        room.removeUser(socket.id);
        socket.to(roomId).emit("user-left", getUsers(roomId));
        socket.leave(roomId);
        socket.emit("room-left");
      };
      

    /**
     * Fait quitter une room à un utilisateur en connaissant son socketId.
     * Si l'utilisateur est l'hôte, supprime la room.
     * @param {string} socketId - L'ID Socket.IO de l'utilisateur
     */
    const leaveRoomWithSocketId = (socketId) => 
        {
            for (let room of rooms) 
            {
                if (room.idSocketHost === socketId) 
                {
                    removeRoom(room.id);
                    return;
                }
          
                const before = room.users.length;
                room.removeUser(socketId);
          
                if (room.users.length < before) 
                {
                    const users = room.getUsernames();
                    socket.leave(room.id);
                    if (room.private) 
                    {
                        socket.to(room.id).emit("user-left-private", users);
                    } 
                    else 
                    {
                        socket.to(room.id).emit("user-left-public", users);
                    }
                    return;
                }
            }
        };

    io.emit("available-rooms", getAvailableRooms());


    //////////////////////////////////////////////////
	///////////////// Listenners /////////////////////
  	//////////////////////////////////////////////////

    socket.on("create-room", (data) => {
        console.log("format recu :", data);
        createRoom(data);
    });

    socket.on("available-rooms", () => {
        socket.emit("available-rooms", getAvailableRooms());
    });


    socket.on("leave-room", leaveRoom);

    socket.on("disconnect", () => {leaveRoomWithSocketId(socket.id);});

    socket.on("users-in-private-room", async (roomId) => {
        const users = await getUsers(roomId);
        socket.emit("users-in-your-private-room", {
          count: users.length,
          users
        });
      });
      

      socket.on("users-in-public-room", async (roomId) => {
        const users = await getUsers(roomId);
        socket.emit("users-in-your-public-room", {
          count: users.length,
          users
        });
      });
      

    socket.on("join-room", async({ roomId, username }) => {
        const room = joinRoom({ roomId, username });
        if (room) 
        {
            socket.join(roomId);
            const users = await getUsers(roomId);
            if (room.private) 
            {
                socket.emit("private-room-joined", users);
                socket.to(roomId).emit("users-in-your-private-room", users);
            }
            else
            {
                socket.emit("public-room-joined", users);
                socket.to(roomId).emit("users-in-your-public-room", users);
            }
        } 
        else
        {
            socket.emit("room-join-failed");
        }
    });
    
};





    //////////////////////////////////////////////////
	////////////// fonctions utilitaires /////////////
  	//////////////////////////////////////////////////
const getAvailableRooms = () => 
{
    return rooms
    .filter(room => room.private === false)
    .map(room => ({
    id: room.id,
    name: room.settings?.lobbyName || "Lobby",
    count: room.users.length,
    playerLimit: room.settings?.playerLimit || 10
    }));
};



const getUsers = async (roomId) => 
{
    const room = rooms.find(r => r.id === roomId);
    if (!room) return { count: 0, users: [] };

    const users = [];

    for (let user of room.users)
    {
        try 
        {
            const player = await Player.findOne({ where: { username: user.username } });
            users.push({
                username: user.username,
                icon: player?.icon || null
            });
        } 
        catch (err) 
        {
            users.push({ username: user.username, icon: null });
        }
    }

    return { count: users.length, users };
};


async function getPlayerID(username) 
{
    try
    {
        const player = await Player.findOne({ where: { username: username } });
        if(player) return player.id;
        else return null;
    }
    catch(err)
    {
        console.log("erreur lors de la recuperation du pllayer ID");
        return null;
    }
    
}



//////////////////////////////////////////////
/////////////// A faire //////////////////////
//////////////////////////////////////////////
//remove bots de la room
//exploitation base de données a la place de room[]
//une fois room startgame elle disparait de available rooms , mais toujours en bdd pour le coup 