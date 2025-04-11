import { io } from "socket.io-client";

const ROOM_ID = process.argv[2]; // à passer en argument
const socket = io("http://185.155.93.105:14001");

socket.on("connect", () => {
  console.log("✅ [Charlie] Connecté :", socket.id);
  if (!ROOM_ID) return console.error("❌ Aucun roomId fourni");

  socket.emit("join-room", {
    roomId: ROOM_ID,
    username: "Charlie"
  });

  socket.on("public-room-joined", (users) => {
    console.log("👥 [Charlie] a rejoint :", users);

    // Quitte après 5 secondes
    setTimeout(() => {
      console.log("🚪 [Charlie] quitte la room");
      socket.emit("leave-room", { roomId: ROOM_ID });
    }, 5000);
  });
});
