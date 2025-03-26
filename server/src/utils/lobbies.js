import { Server } from "socket.io";
import randomstring from "randomstring";

const ID_LENGTH = 5;
const NB_PLAYERS_MAX_IN_LOBBY = 10;

class LobbyUser {
  constructor(username, idSocketUser) {
    this.username = username;
    this.idSocketUser = idSocketUser;
  }
}

class Lobby {
  constructor(id, host, idSocketHost, isPrivate = false) {
    this.id = id;
    this.host = host;
    this.idSocketHost = idSocketHost;
    this.users = [];
    this.private = isPrivate;
  }

  addUser(username, idSocketUser) {
    this.users.push(new LobbyUser(username, idSocketUser));
  }

  removeUser(idSocketUser) {
    this.users = this.users.filter(user => user.idSocketUser !== idSocketUser);
  }

  getUsernames() {
    return this.users.map(user => user.username);
  }

  isFull() {
    return this.users.length >= NB_PLAYERS_MAX_IN_LOBBY;
  }
}

export let rooms = [];

export const roomHandler = (socket, io) => 
{
  const getAvailableRooms = () =>
    rooms.filter(room => !room.private).map(room => room.id);

  const getUsers = (roomId) => {
    const room = rooms.find(r => r.id === roomId);
    return room ? room.getUsernames() : [];
  };

  socket.emit("available-rooms", getAvailableRooms());

  const createRoom = (username) => {
    const roomId = randomstring.generate({ length: ID_LENGTH, charset: "alphanumeric" });
    const newRoom = new Lobby(roomId, username, socket.id);
    newRoom.addUser(username, socket.id);
    rooms.push(newRoom);

    socket.join(roomId);
    io.emit("available-rooms", getAvailableRooms());
    socket.emit("private-room-created", roomId);
  };

  const removeRoom = (roomId) => {
    rooms = rooms.filter(r => r.id !== roomId);
    io.to(roomId).emit("remove-private-room");
    io.emit("available-rooms", getAvailableRooms());
  };

  const joinRoom = ({ roomId, username }) => {
    const room = rooms.find(r => r.id === roomId);
    if (!room) {
      socket.emit("private-room-not-found");
      return;
    }
    if (room.isFull()) {
      return false;
    }
    room.addUser(username, socket.id);
    return true;
  };

  const leaveRoom = ({ roomId, host, socketId }) => {
    const room = rooms.find(r => r.id === roomId);
    if (!room) return;

    if (host) {
      removeRoom(roomId);
      socket.to(roomId).emit("remove-private-room");
      socket.leave(roomId);
      socket.emit("private-room-lefted");
      return;
    }

    room.removeUser(socketId);
    socket.to(roomId).emit("user-left", getUsers(roomId));
    socket.leave(roomId);
    socket.emit("private-room-lefted");
  };

  const leaveRoomWithSocketId = (socketId) => {
    for (let room of rooms) {
      if (room.idSocketHost === socketId) {
        removeRoom(room.id);
        socket.to(room.id).emit("remove-private-room", getAvailableRooms());
        socket.leave(room.id);
        return;
      }

      const before = room.users.length;
      room.removeUser(socketId);

      if (room.users.length < before) {
        socket.to(room.id).emit("user-left", getUsers(room.id));
        socket.leave(room.id);
        return;
      }
    }
  };

  // Sockets
  socket.on("create-room", createRoom);

  socket.on("users-in-private-room", (roomId) => {
    socket.emit("users-in-your-private-room", getUsers(roomId));
  });

  socket.on("join-room", ({ roomId, username }) => {
    const success = joinRoom({ roomId, username });
    if (success) {
      socket.join(roomId);
      socket.emit("private-room-joined", getUsers(roomId));
      socket.to(roomId).emit("users-in-your-private-room", getUsers(roomId));
    } else if (success === false) {
      socket.emit("private-room-is-full");
    }
  });

  socket.on("leave-room", leaveRoom);
  socket.on("disconnect", () => {
    leaveRoomWithSocketId(socket.id);
  });
};
