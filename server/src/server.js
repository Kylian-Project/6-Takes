// server.js
import db from "./config/db.js";
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import http from "http";

import { Server } from "socket.io";
import { PlayGame } from "./utils/partie.js";
import { roomHandler } from "./utils/lobbies.js";

import playerRoutes from "./routes/player_route.js";


// ------------------------
// ?? EXPRESS API REST
// ------------------------
const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/player", playerRoutes);

// Serveur HTTP (Express + WebSocket)
const server = http.createServer(app);

// ------------------------
// WebSocket tbc...
// ------------------------

const io = new Server(server, {
  cors: {
    origin: "*",          // to change in Prod
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true     // as we use headers for JWT
  },
});

io.on("connection",(socket) => {
  console.log("Un client s'est connecté :", socket.id);
  roomHandler(socket, io);
  PlayGame(socket, io);
});



// ------------------------
// ?? LANCEMENT
// ------------------------
const PORT = process.env.PORT;

db.sync().then(() => {
  server.listen(PORT, () => {
    console.log(`Serveur HTTP & WebSocket en ligne sur le port ${PORT}`);
    console.log(`API: http://bastion:${PORT}/api/player`);
  });
}).catch((err) => {
  console.error("Erreur de connexion à la base de données :", err);
});
