import { io } from "socket.io-client";
import readline from "readline";

const socket = io("http://185.155.93.105:14001");

let roomId;
let hand = [];
let compteur=0;

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
    //socket.emit("tour", roomId);      //lancer le tour
    console.log("start game envoyé");
    //askCarte();
  });
  
function askCarte() {
  socket.emit("tour" , {roomId, username:"Bob"});
  console.log(("start-tour envooyé"));
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
  if(compteur==0)
  {
    askCarte();
    compteur++;
  }
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


socket.on("temps-room",(secondeRestantes)=>{
  //console.log(`Temps restant: ${secondeRestantes} secondes`);
});



socket.on("attente-choix-rangee", () => 
{
    console.log("Attent quelqu'un choisit une rangee");
});

socket.on("ramassage_rang", (data) => 
  {
      console.log("Ce joueur vient de ramasser tout une rangée -> " ,data);
  });


socket.on("manche-suivante", () => 
{
    console.log("Nouvelle manche ");
    // on peut afficher les score de tout le monde pendant X secondes
    socket.emit("tour" , {roomId, username:"Bob"});
  });



socket.on("end-game", ({ classement }) => {
  console.log("\n🏆 FIN DE PARTIE !");
  console.log("📋 Classement final :");
  
  classement.forEach((joueur, index) => {
    console.log(` ${index + 1}. ${joueur.nom} → ${joueur.score} 🐮`);
  });

  console.log("Merci d'avoir joué !");
  process.exit(0); // Termine proprement le processus
});
