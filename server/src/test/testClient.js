import { io } from "socket.io-client";

const socket = io("http://185.155.93.105:14001"); // <== IP publique du bastion + port redirigé

socket.on("connect", () => {
  console.log("✅ Connecté au serveur avec ID :", socket.id);

  // Création d'une room privée
  socket.emit("create-room", {
    username: "Alice",
    isPrivate: false,
  });

  socket.on("private-room-created", (roomId) => {
    console.log("🔒 Room privée créée :", roomId);

    const socketBob = io("http://185.155.93.105:14001");
    socketBob.on("connect", () => {
      console.log("👤 Bob connecté :", socketBob.id);
      socketBob.emit("join-room", { roomId, username: "Bob" });

      socketBob.on("private-room-joined", (users) => {
        console.log("👥 Bob a rejoint la room d’Alice :", users);
      });
    });
  });
});
