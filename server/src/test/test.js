import { Jeu6Takes } from "../algo/6takesgame.js";

const joueurs = ["Alice", "Bob", "Charlie"];
const jeu = new Jeu6Takes(joueurs.length, joueurs);

console.log("Cartes de chaque joueur :");
jeu.joueurs.forEach(j => {
  console.log(`${j.nom} :`, j.getHand().map(c => c.numero));
});

console.log("\nTable initiale :");
jeu.table.rangs.forEach((rang, i) => {
  console.log(`Rang ${i + 1} : ${rang.cartes[0].numero}`);
});
