import { io } from "socket.io-client";
import readline from "readline";

const socket = io("http://185.155.93.105:14001");

let roomId;
let hand = [];

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question("🔑 Entrez le roomId à rejoindre : ", (inputRoomId) => {
  roomId = inputRoomId;
  console.log("le code de la room est : ",roomId);
  socket.emit("join-room", { roomId, username: "Bob" });
  
});

  socket.on("private-room-joined", (users) => {
    console.log("👥 Bob a rejoint la room :", users);
    socket.emit("start-game", roomId);
    console.log("start game envoyé");
  });
  
function askCarte() {
  console.log("🃏 Votre main :", hand.map((c, i) => `(${i}) ${c}`).join(" | "));
  rl.question("👉 Quelle carte voulez-vous jouer ? (index) ", (input) => 
  {
    const index = parseInt(input);
    if (isNaN(index) || index < 0 || index >= hand.length) {
      console.log("❌ Index invalide.");
      return askCarte();
    }
    const card = hand.splice(index, 1)[0];
    socket.emit("play-card", { roomId, card, username: "Bob" });
    console.log("play card envoyé");
  });
}

socket.on("connect", () => {
  console.log("✅ Bob connecté :", socket.id);
});

socket.on("your-hand", (cartes) => {
  hand = cartes;
  console.log("🖐️ Nouvelle main reçue :", hand);
  askCarte();
});

socket.on("update-table", (table) => {
  console.log("🧩 Table mise à jour :");
  table.forEach((rang, i) => {
    console.log(`  Rangée ${i + 1} : [${rang.join(", ")}]`);
  });
});

socket.on("update-scores", (scores) => {
  console.log("🏆 Scores :");
  scores.forEach(s => console.log(`  ${s.nom} : ${s.score} 🐮`));
  askCarte();
});

socket.on("tour", (nom) => {
  if (nom === "Bob" && hand.length > 0) {
    askCarte();
  }
});

socket.on("choix-rangee", ({ rangs }) => {
  console.log("⚠️ Choix obligatoire d'une rangée :");
  rangs.forEach((r, i) => {
    console.log(`  (${i}) Rangée : [${r.cartes.join(", ")}], Pénalité: ${r.penalite}`);
  });
  rl.question("👉 Choisir une rangée : ", (input) => {
    const indexRangee = parseInt(input);
    socket.emit("choisir-rangee", { roomId, indexRangee, username: "Bob" });
  });
});
