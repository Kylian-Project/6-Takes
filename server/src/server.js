const http = require("http");
require("dotenv").config();
const { Server } = require("socket.io");

const express = require("express");
const app = express();


// Add les routes HTTP 


// Creation server HTTP
const server = http.createServer(app);

// Initialisation de Socket.io
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["POST"]   // for now, w/out "GET"
  }
});

// WebSocket
io.on("connection", (socket) => {
  console.log("Un joueur s'est connecté :", socket.id);

  socket.on("createRoom", (data) => {
    console.log("Création d’un salon :", data);
  });

  socket.on("joinRoom", (roomCode) => {
    socket.join(roomCode);
    console.log(`${socket.id} a rejoint la salle ${roomCode}`);
  });

  socket.on("disconnect", () => {
    console.log("Déconnexion de :", socket.id);
  });
});

const PORT = process.env.PORT || 3000;      // indicated the correct port on .env , in case it fails use 3000
server.listen(PORT, () => {
  console.log(`Serveur WebSocket en écoute sur le port ${PORT}`);
});