import { Server } from "socket.io";
import randomstring from "randomstring";
import Lobby from "../models/lobbies.js"; // <-- Le modèle Sequelize


const ID_LENGTH = 5;
const NB_PLAYERS_MAX_IN_ROOM = 10;

class RoomUser {
    constructor(username, idSocketUser) {
    this.username = username;
    this.idSocketUser = idSocketUser;
  }
}

class Room {
    constructor(id, host, idSocketHost, isPrivate) {
    this.id = id;
    this.host = host;
    this.idSocketHost = idSocketHost;
    this.users = [];
    this.private = isPrivate;
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
        return this.users.length >= NB_PLAYERS_MAX_IN_ROOM;
    }
}

export let rooms = [];

export const roomHandler = (socket, io) => 
{   
        //fonction utile 
    const getAvailableRooms = () => {
        return rooms.filter(room => room.private === false).map(room => room.id);
    };


    const getUsers = (roomId) => {
        const room = rooms.find(r => r.id === roomId);
        return room ? room.getUsernames() : [];
    };

    //fonctions principales


    /*const createRoom = async ({ username, isPrivate }) => 
    {
        //async pour attendre la promesse
        const roomId = randomstring.generate({ length: ID_LENGTH, charset: "alphanumeric" });
        const newRoom = new Room(roomId, username, socket.id, isPrivate);      //on crée une instance de Room
        newRoom.addUser(username, socket.id);   //on ajoute un user(host) dessus
        rooms.push(newRoom);    //on push la nouvelle room (Room) dans le tableau des rooms globales
        
        try
        {
            //une fois le syteme d'auth terminé je peux remplacer par "id_creator: socket.playerId"
            await Lobby.create(
            {
                id_creator: 1,      //temporraire
                name: roomId,
                state: isPrivate ? "PRIVATE" : "PUBLIC",
            });
          console.log("✅ Room enregistrée en BDD :", roomId);    //test
        } 
        catch (err) {
            console.error("❌ Erreur BDD :", err.message);
        }
      
        socket.join(roomId);
        io.emit("available-rooms", getAvailableRooms());
        socket.emit(isPrivate ? "private-room-created" : "public-room-created", roomId);
    };*/

    const createRoom = async ({
        username,
        lobbyName,
        playerLimit = 10,
        numberOfCards = 10,
        roundTimer = 45,
        endByPoints = 66,
        rounds = 1,
        isPrivate
      }) => {
        const roomId = randomstring.generate({ length: ID_LENGTH, charset: "alphanumeric" });
      
        // Création de la room avec les paramètres
        const newRoom = new Room(roomId, username, socket.id, isPrivate);
        newRoom.addUser(username, socket.id);
        console.log("✅ Room créee : " , RoomId);
        // Ajout des paramètres personnalisés
        newRoom.settings = {
          lobbyName,
          playerLimit,
          numberOfCards,
          roundTimer,
          endByPoints,
          rounds
        };
      
        rooms.push(newRoom);
      
        try {
          await Lobby.create({
            id_creator: 1, // Remplacer plus tard par socket.playerId
            name: lobbyName || roomId, // si aucun nom fourni, fallback au roomId
            state: isPrivate ? "PRIVATE" : "PUBLIC",
          });
      
          console.log("✅ Room enregistrée en BDD :", lobbyName || roomId);
        } catch (err) {
          console.error("❌ Erreur BDD :", err.message);
        }
      
        socket.join(roomId);
        io.emit("available-rooms", getAvailableRooms());
      
        socket.emit(isPrivate ? "private-room-created" : "public-room-created", roomId);
      };

    const removeRoom = (roomId) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) return;
        rooms = rooms.filter(r => r.id !== roomId);
        if (room.isPrivate) 
        {
            io.to(roomId).emit("remove-private-room");  //pour tout les membres
        } 
        else 
        {
            io.to(roomId).emit("remove-public-room");
        }
        io.emit("available-rooms", getAvailableRooms());
    };

    const joinRoom = ({ roomId, username }) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) 
        {
            socket.emit("room-not-found");
            return;
        }
        if (room.isFull()) 
        {
            return false;
        }
        room.addUser(username, socket.id);
        return room;
    };

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
                    if (room.isPrivate) 
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


    //sockets listenners
    //socket.on("create-room", createRoom);
/*
    socket.on("create-room", (data) => {
        if (data && typeof data === 'object') {
          createRoom(data);
        } else {
          console.warn("[create-room] Format invalide reçu :", data);
          socket.emit("room-creation-failed", "Invalid data format.");
        }
      });
*/
    socket.on("create-room", (data) => {
        console.log("format recu :", data);
        createRoom(data);
      });
    //socket.on("create-room", createRoom);
    
    socket.on("leave-room", leaveRoom);
    socket.on("disconnect", () => {leaveRoomWithSocketId(socket.id);});
    socket.on("users-in-private-room", (roomId) => {
        socket.emit("users-in-your-private-room", getUsers(roomId));});

    socket.on("join-room", ({ roomId, username }) => 
    {
        const room = joinRoom({ roomId, username });
        if (room) 
        {
            socket.join(roomId);
            const users = getUsers(roomId);
            if (room.isPrivate) 
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