import express from "express";
import http from "http";
import { Server } from "socket.io";
import { PlayGame } from "./utils/partie.js";
import { roomHandler } from "./utils/lobbies.js";

const app = express();
const server = http.createServer(app);
const port = 8080;

const io = new Server(server, { cors: { origin: "http://localhost:3000" } });

io.on("connection", (socket) => {
  console.log("a user connected", socket.id);
  roomHandler(socket, io);
  PlayGame(socket, io);
});

server.listen(port, () => {
  console.log(`listening on http://localhost:${port}`);
});
