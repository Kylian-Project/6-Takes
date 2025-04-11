import { io } from "socket.io-client";

const ROOM_ID = process.argv[2]; // à passer en argument
const socket = io("http://185.155.93.105:14001");

socket.on("connect", () => {
  console.log("✅ [Dave] Connecté :", socket.id);
  if (!ROOM_ID) return console.error("❌ Aucun roomId fourni");

  socket.emit("join-room", {
    roomId: ROOM_ID,
    username: "Dave"
  });

  socket.on("public-room-joined", (users) => {
    console.log("👥 [Dave] a rejoint la room :", users);
  });

  socket.on("room-join-failed", () => {
    console.log("❌ [Dave] La room est pleine !");
  });
});
