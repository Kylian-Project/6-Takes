import { io } from "socket.io-client";

const socket = io("http://localhost:8080"); // Change si tu utilises un autre port

socket.on("connect", () => {
  console.log("✅ Connecté au serveur avec ID :", socket.id);

  // 👇 Test 1 : créer une room
  socket.emit("create-room", "Alice");

  // 👇 Quand la room est créée, simule un autre joueur
  socket.on("private-room-created", (roomId) => {
    console.log("📦 Room créée :", roomId);

    // Nouvelle "connexion" simulée (autre joueur)
    const socket2 = io("http://localhost:8080");

    socket2.on("connect", () => {
      console.log("🔗 2e joueur connecté :", socket2.id);
      socket2.emit("join-room", { roomId, username: "Bob" });

      socket2.on("private-room-joined", (users) => {
        console.log("🧑‍🤝‍🧑 Joueurs dans la room :", users);
      });

      // Voir la liste des joueurs de la salle
      socket2.emit("users-in-private-room", roomId);
      socket2.on("users-in-your-private-room", (users) => {
        console.log("👥 Liste actuelle :", users);
      });
    });
  });
});
