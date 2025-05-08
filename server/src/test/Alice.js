import { io } from "socket.io-client";
import readline from "readline";

const socket = io("http://185.155.93.105:14003");

let roomId;
let hand = [];
let compteur=0;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askCarte() {
  socket.emit("tour" , {roomId, username:"neila"});
  console.log(("start-tour envooyé"));
  console.log("🃏 Votre main :", hand.map((c, i) => `(${i}) ${c}`).join(" | "));
  rl.question("👉 Quelle carte voulez-vous jouer ? (index) ", (input) => {
    const index = parseInt(input);
    if (isNaN(index) || index < 0 || index >= hand.length) {
      console.log("❌ Index invalide.");
      return askCarte();
    }
    const card = hand.splice(index, 1)[0];
    socket.emit("play-card", { roomId, card, username: "neila" });
        console.log("play card envoyé");
  });
}

socket.on("connect", () => {
  console.log("✅ neila connectée :", socket.id);
  socket.emit("create-room", {
    username: "neila",
    isPrivate: "PRIVATE",
    lobbyName: "TestTerminal",
    playerLimit: 10,
    numberOfCards: 5,
    roundTimer: 45,
    endByPoints: 50,
    rounds: 2
  });
});

socket.on("private-room-created", (id) => {
  roomId = id;
  console.log("📦 Room créée :", roomId);

//   setTimeout(() => {
//   console.log("🚪 neila demande un kick lounas");
//   socket.emit("kick-player", { roomId, username:"Bot1234" });
// }, 15000);


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

socket.on("tour", (nom) => {
  if (nom === "neila" && hand.length > 0) {
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
    socket.emit("choisir-rangee", { roomId, indexRangee, username: "neila" });
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
      //socket.emit("tour" , {roomId, username:"neila"});
      //compteur=0;
      askCarte();
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
        
          




socket.on("user-kicked", (data) => {
  console.log("🚪 neila a kick ", data);
});


socket.on("users-in-your-private-room", (users) => {
  console.log("👥 utilisateurs de la ROOM sont  :", users);
});



socket.on("users-in-your-public-room", (users) => {
  console.log("👥 utilisateurs de la ROOM sont :", users);
});



socket.on("score-manche", ({ classement }) => {
  console.log("\n🏆 FIN DE MANCHE !");
  console.log("📋 Classement dans cette manche :");
  
  classement.forEach((joueur, index) => {
    console.log(` ${index + 1}. ${joueur.nom} → ${joueur.score} 🐮`);
  });

});