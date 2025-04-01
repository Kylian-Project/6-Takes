// server.js
require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");

const db = require("./config/db"); // Sequelize DB
const playerRoutes = require("./routes/player_route");
const verifySocketToken = require("./middleware/authWS");

const app = express();
app.use(cors());
app.use(express.json());

// API REST
app.use("/api/player", playerRoutes);

// Server HTTP
const server = http.createServer(app);

// WebSocket Server
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on("connection", async (socket) => {
  console.log("Nouvelle connexion WebSocket :", socket.id);
  console.log("Paramètres d'authentification :", socket.handshake.query);

  try {
    const playerId = await verifySocketToken(socket); // Vérifie le token dans l'URL

    socket.playerId = playerId;
    console.log(`Authentification réussie pour le joueur ID ${playerId} via WebSocket`);

    // Écoute des événements
    socket.on("signin", () => {
      console.log("Joueur connecté :", socket.playerId);
    });

    socket.on("signup", () => {
      console.log("Inscription joueur :", socket.playerId);
    });

    socket.on("disconnect", () => {
      console.log("Joueur déconnecté :", socket.playerId);
    });

  } catch (err) {
    console.log("Connexion refusée :", err.message);
    socket.emit("error", { message: "Token invalide ou expiré" });
    socket.disconnect();
  }
});

// Lancer l'app
const PORT = process.env.PORT || 14001;
db.sync().then(() => {
  server.listen(PORT, () => {
    console.log(`🚀 Serveur lancé sur le port : ${PORT}`);
    console.log(`🌐 WebSocket accessible sur ws://<host>:${PORT}/?token=<jwt>`);
  });
});
