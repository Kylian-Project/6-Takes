// server.js
require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const { Server } = require("socket.io");

const db = require("./config/db"); // Sequelize DB
const playerRoutes = require("./routes/player_route");

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

io.on("connection", (socket) => {
  console.log("Un joueur s'est connecté :", socket.id);

  socket.on("createRoom", (data) => {
    console.log("Salon créé :", data);
    // À relier à la logique de partie
  });

  socket.on("joinRoom", (roomCode) => {
    socket.join(roomCode);
    console.log(`${socket.id} a rejoint le salon ${roomCode}`);
  });

  socket.on("disconnect", () => {
    console.log("Déconnexion de :", socket.id);
  });
});

// Lancer l'app
const PORT = process.env.PORT || 3000;
db.sync().then(() => {
  server.listen(PORT, () => {
    console.log(`Serveur lancé sur http://localhost:${PORT}`);
  });
});
