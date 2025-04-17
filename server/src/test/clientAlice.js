import { io } from "socket.io-client";
import readline from "readline";

const socket = io("http://185.155.93.105:14002");

let roomId;
let hand = [];

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askCarte() {
  socket.emit("tour" , {roomId});
  console.log(("evebnement tour-start envooyé"));
  console.log("🃏 Votre main :", hand.map((c, i) => `(${i}) ${c}`).join(" | "));
  rl.question("👉 Quelle carte voulez-vous jouer ? (index) ", (input) => {
    const index = parseInt(input);
    if (isNaN(index) || index < 0 || index >= hand.length) {
      console.log("❌ Index invalide.");
      return askCarte();
    }
    const card = hand.splice(index, 1)[0];
    socket.emit("play-card", { roomId, card, username: "Alice" });
        console.log("play card envoyé");
  });
}

socket.on("connect", () => {
  console.log("✅ Alice connectée :", socket.id);
  socket.emit("create-room", {
    username: "Alice",
    isPrivate: "PRIVATE",
    lobbyName: "TestTerminal",
    playerLimit: 2,
    numberOfCards: 10,
    roundTimer: 10,
    endByPoints: 66,
    rounds: 1
  });
});

socket.on("private-room-created", (id) => {
  roomId = id;
  console.log("📦 Room créée :", roomId);
});

socket.on("your-hand", (cartes) => {
  hand = cartes;
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
  //socket.emit("tour" , {roomId});
  askCarte();
});

socket.on("tour", (nom) => {
  if (nom === "Alice" && hand.length > 0) {
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
    socket.emit("choisir-rangee", { roomId, indexRangee, username: "Alice" });
  });
});




