import { io } from "socket.io-client";

const socket = io("http://185.155.93.105:14001");

socket.on("connect", () => {
  console.log("✅ [Alice] Connectée :", socket.id);

  socket.emit("create-room", {
    username: "Alice",
    lobbyName: "SuperLobby",
    playerLimit: 3,
    numberOfCards: 10,
    roundTimer: 30,
    endByPoints: 66,
    rounds: 1,
    isPrivate: "PUBLIC"
  });

  socket.on("public-room-created", (roomId) => {
    console.log("📦 [Alice] Room créée :", roomId);
    console.log("📝 Copie ce roomId pour les autres tests :", roomId);
  });

  socket.on("users-in-your-public-room", (users) => {
    console.log("👥 [Alice] utilisateurs :", users);
  });
});
