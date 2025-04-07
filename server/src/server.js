// server.js
import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import http from "http";
import jwt from "jsonwebtoken";
import { WebSocketServer } from "ws";

import db from "./config/db.js";
import playerRoutes from "./routes/player_route.js";
import Session from "./models/session.js";
import Player from "./models/player.js";
import lobbyRoutes from "./routes/lobby_route.js";


// ------------------------
// ?? EXPRESS API REST
// ------------------------
const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/player", playerRoutes);
app.use("/api/lobbies", lobbyRoutes);

// Serveur HTTP (Express + WebSocket)
const server = http.createServer(app);

// ------------------------
// WebSocket tbc...
// ------------------------

const wss = new WebSocketServer({ server });

wss.on("connection", async (ws, request) => {
  const url = new URL(request.url, `http://${request.headers.host}`);
  const token = url.searchParams.get("token");

  if (!token) {
    ws.send(JSON.stringify({ error: "Token manquant" }));
    return ws.close();
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const session = await Session.findOne({
      where: {
        id_player: decoded.id,
        token
      }
    });

    if (!session || new Date() > session.expire_at) {
      ws.send(JSON.stringify({ error: "Session expirée ou invalide" }));
      return ws.close();
    }

    ws.playerId = decoded.id;

    const player = await Player.findByPk(ws.playerId);
    const username = player?.username || "Inconnu";

    console.log(`?? [WS] Connecté : ${username} (ID ${ws.playerId})`);
    ws.send(JSON.stringify({ message: "Connexion WebSocket réussie", playerId: ws.playerId }));

    ws.on("message", (msg) => {
      console.log("?? WS - Message reçu :", msg.toString());
    });

    ws.on("close", async () => {
      const player = await Player.findByPk(ws.playerId);
      const username = player?.username || "Inconnu";
      console.log(`? [WS] Déconnecté : ${username} (ID ${ws.playerId})`);
    });

  } catch (err) {
    ws.send(JSON.stringify({ error: "Token invalide" }));
    ws.close();
  }
});

// ------------------------
// ?? LANCEMENT
// ------------------------
const PORT = process.env.PORT;

db.sync().then(() => {
  server.listen(PORT, () => {
    console.log(`? Serveur HTTP & WebSocket en ligne sur le port ${PORT}`);
    console.log(`?? API: http://localhost:${PORT}/api/player`);
    console.log(`?? WS : ws://localhost:${PORT}/?token=<JWT>`);
  });
}).catch((err) => {
  console.error("? Erreur de connexion à la base de données :", err);
});
