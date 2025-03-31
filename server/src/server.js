// server.js
require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");

const db = require("./config/db"); // Sequelize DB
const playerRoutes = require("./routes/player_route");
const verifySocketToken = require("./middleware/auth");

const app = express();
app.use(cors());
app.use(express.json());

// API REST
app.use("/api/player", playerRoutes);

// Server HTTP
const server = http.createServer(app);

// WebSocket
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on("connection", async (socket) => {
  console.log("Une personne essaie de se connecter :", socket.id);

  try {
    const playerId = await verifySocketToken(socket);
    socket.playerId = playerId;

    console.log(`Joueur ${playerId} connecté via WebSocket`);

    socket.on("signin", () => {
      console.log("Connexion d'un joueur :", socket.playerId);
    });

    socket.on("signup", () => {
      console.log("Sign up nouveau joueur :", socket.playerId);
    });

    socket.on("disconnect", () => {
      console.log("Joueur déconnecté :", socket.playerId);
    });

  } catch (err) {
    console.log("Connexion refusée :", err.message);
    socket.disconnect();
  }
});

// Lancer l'app
const PORT = process.env.PORT;
db.sync().then(() => {
  server.listen(PORT, () => {
    console.log(`Serveur lancé sur le port : ${PORT}`);
  });
});
