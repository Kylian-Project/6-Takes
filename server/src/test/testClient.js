import { io } from "socket.io-client";

const BASE_URL = "http://185.155.93.105:14001";

const socketAlice = io(BASE_URL);
let roomId = "";

socketAlice.on("connect", () => {
  console.log("✅ Alice connectée :", socketAlice.id);

  socketAlice.emit("create-room", {
    username: "Alice",
    lobbyName: "TestRoom",
    playerLimit: 2,
    numberOfCards: 10,
    roundTimer: 30,
    endByPoints: 66,
    rounds: 1,
    isPrivate: "PUBLIC"
  });

  socketAlice.on("public-room-created", (id) => {
    console.log("📦 Room publique créée :", id);
    roomId = id;
    joinBob();
  });

  socketAlice.on("users-in-your-public-room", (users) => {
    console.log("👥 [Alice] utilisateurs :", users);
  });
});

function joinBob() {
  const socketBob = io(BASE_URL);
  socketBob.on("connect", () => {
    console.log("👤 Bob connecté :", socketBob.id);
    socketBob.emit("join-room", { roomId, username: "Bob" });
  });

  socketBob.on("public-room-joined", (users) => {
    console.log("✅ Bob a rejoint la room :", users);
    joinCharlie();
  });

  function joinCharlie() {
    const socketCharlie = io(BASE_URL);
    socketCharlie.on("connect", () => {
      console.log("🧍 Charlie tente de rejoindre (devrait échouer)");
      socketCharlie.emit("join-room", { roomId, username: "Charlie" });
    });

    socketCharlie.on("room-join-failed", () => {
      console.log("❌ Charlie a été refusé (room pleine)");
    });
  }
}
