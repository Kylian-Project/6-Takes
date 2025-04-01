import { io } from "socket.io-client";

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const testScenario = async () => {


  const socketAlice = io("http://localhost:8080");

  socketAlice.on("connect", () => {
    console.log("✅ Alice connectée :", socketAlice.id);

    // Alice crée une room PRIVÉE
    socketAlice.emit("create-room", { username: "Alice", isPrivate: true });

    socketAlice.on("private-room-created", async (roomId) => {
      console.log("🔒 Room privée créée par Alice :", roomId);

      // Bob se connecte et rejoint la room d'Alice
      const socketBob = io("http://localhost:8080");
      socketBob.on("connect", () => {
        console.log("👤 Bob connecté :", socketBob.id);
        socketBob.emit("join-room", { roomId, username: "Bob" });

        socketBob.on("private-room-joined", (users) => {
          console.log("👥 Bob a rejoint la room d'Alice. Users:", users);
        });

        socketBob.emit("users-in-private-room", roomId);
        socketBob.on("users-in-your-private-room", (users) => {
          console.log("📋 Utilisateurs (room Alice) :", users);
        });

        // Bob quitte après 3s
        setTimeout(() => {
          socketBob.emit("leave-room", {
            roomId,
            host: false,
            socketId: socketBob.id
          });
          console.log("👋 Bob quitte la room");
        }, 3000);
      });

      // Alice quitte après 6s
      setTimeout(() => {
        socketAlice.emit("leave-room", {
          roomId,
          host: true,
          socketId: socketAlice.id
        });
        console.log("🧑‍✈️ Alice (host) quitte la room (elle sera supprimée)");
      }, 6000);
    });

    // Création de la room PUBLIQUE par Charlie
    setTimeout(() => {
      const socketCharlie = io("http://localhost:8080");
      socketCharlie.on("connect", () => {
        console.log("🧑 Charlie connecté :", socketCharlie.id);
        socketCharlie.emit("create-room", {
          username: "Charlie",
          isPrivate: false
        });

        socketCharlie.on("public-room-created", (roomId) => {
          console.log("🌍 Room publique créée par Charlie :", roomId);

          // Dave rejoint la room publique
          const socketDave = io("http://localhost:8080");
          socketDave.on("connect", () => {
            console.log("👤 Dave connecté :", socketDave.id);
            socketDave.emit("join-room", { roomId, username: "Dave" });

            socketDave.on("private-room-joined", (users) => {
              console.log("👥 Dave a rejoint la room publique. Users:", users);
            });

            socketDave.emit("users-in-private-room", roomId);
            socketDave.on("users-in-your-private-room", (users) => {
              console.log("📋 Utilisateurs (room Charlie) :", users);
            });

            // Dave quitte après 5s
            setTimeout(() => {
              socketDave.emit("leave-room", {
                roomId,
                host: false,
                socketId: socketDave.id
              });
              console.log("👋 Dave quitte la room publique");
            }, 5000);
          });
        });
      });
    }, 2000);
  });

  // 🔁 Observer la liste des rooms disponibles toutes les 2s
  const observer = io("http://localhost:8080");
  observer.on("connect", () => {
    setInterval(() => {
      observer.emit("available-rooms");
    }, 2000);

    observer.on("available-rooms", (rooms) => {
      console.log("📡 Rooms disponibles :", rooms);
    });
  });
};

testScenario();
