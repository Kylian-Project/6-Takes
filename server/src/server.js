import dotenv from "dotenv";
dotenv.config();
import express from "express";
import http from "http";
import { Server } from "socket.io";
import { PlayGame } from "./utils/partie.js";
import { roomHandler } from "./utils/lobbies.js";




const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 14001;



const io = new Server(server, {
  cors: {
    origin: "*", // tu pourras sécuriser plus tard si besoin
  },
});

io.on("connection", (socket) => {
  console.log("✅ Un client s'est connecté :", socket.id);
  roomHandler(socket, io);    
  PlayGame(socket, io);       
});

// Lancer le serveur
server.listen(PORT, () => {
  console.log(`🚀 Serveur WebSocket actif sur le port ${PORT}`);
});
