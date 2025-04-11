import { io } from "socket.io-client";

const socket = io("http://185.155.93.105:14001");

socket.on("connect", () => {
  console.log("👁️ [Spectateur] connecté :", socket.id);
  socket.emit("available-rooms");
});

socket.on("available-rooms", (roomIds) => {
  console.log("📡 Rooms publiques disponibles :", roomIds);
});
