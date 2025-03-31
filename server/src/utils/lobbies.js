import { Server } from "socket.io";
import randomstring from "randomstring";

const ID_LENGTH = 5;
const NB_PLAYERS_MAX_IN_ROOM = 10;

class RoomUser {
    constructor(username, idSocketUser) {
    this.username = username;
    this.idSocketUser = idSocketUser;
  }
}

class Room {
    constructor(id, host, idSocketHost, isPrivate = false) {
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
        return this.users.length >= NB_PLAYERS_MAX_IN_Room;
    }
}

export let rooms = [];

export const roomHandler = (socket, io) => 
{   
        //fonction utile 
    const getAvailableRooms = () => {
        return rooms.filter(room => room.isPrivate === false).map(room => room.id);
    };


    const getUsers = (roomId) => {
        const room = rooms.find(r => r.id === roomId);
        return room ? room.getUsernames() : [];
    };

    //fonctions principales
    const createRoom = ({ username, isPrivate=false }) => 
    {
        const roomId = randomstring.generate({ length: ID_LENGTH, charset: "alphanumeric" });
        const newRoom = new Room(roomId, username, socket.id, isPrivate); //on crée une instance de Room
        newRoom.addUser(username, socket.id);       //on ajoute un user(host) dessus
        rooms.push(newRoom);    //on push la nouvelle room (Room) dans le tableau des rooms globales
        socket.join(roomId);
        io.emit("available-rooms", getAvailableRooms());
        if(isPrivate)
        {
            socket.emit("private-room-created", roomId);
        }
        else
        {
            socket.emit("public-room-created", roomId);
        }
        socket.emit("private-room-created", roomId);
    };

    const removeRoom = (roomId) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) return;
        rooms = rooms.filter(r => r.id !== roomId);
        if (room.isPrivate) 
        {
            io.to(roomId).emit("remove-private-room");
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

    const leaveRoom = ({ roomId, host, socketId }) => 
    {
        const room = rooms.find(r => r.id === roomId);
        if (!room) return;
    
        if (host) 
        {
            removeRoom(roomId);
            socket.leave(roomId);
            socket.emit("room-lefted");
            return;
        }
        room.removeUser(socketId);
        socket.leave(roomId);
        socket.emit("room-lefted");
    
        const users = getUsers(roomId);
        if (room.isPrivate)
        {
            socket.to(roomId).emit("user-left-private", users);
        } 
        else 
        {
            socket.to(roomId).emit("user-left-public", users);
        }
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
    socket.on("create-room", createRoom);
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
