// test_signin-up.js
require("dotenv").config();
const axios = require("axios");

const BASE_URL = `http://${process.env.SRV_URL}:${process.env.SRV_PORT}/api/player`;


const testCredentials = {
  username: "clientTest", 
  password: "azerty99"
};

// CONNEXION UNIQUEMENT
async function login() {
  console.log("Tentative de connexion avec :", testCredentials);
  try {
    const res = await axios.post(`${BASE_URL}/connexion`, testCredentials);

    const player = res.data.player;
    const token = res.data.token;

    console.log("Connexion réussie !");
    console.log("Infos joueur :", player);
    console.log("Token JWT :", token);

    return token;
  } catch (err) {
    const errorData = err.response?.data || err.message;
    console.error("Erreur lors de la connexion :", errorData);

    if (err.response?.status === 404) {
      console.error("Aucun utilisateur trouvé avec ce nom.");
    } else if (err.response?.status === 401) {
      console.error("Mot de passe incorrect.");
    } else if (err.response?.status === 500) {
      console.error("Erreur serveur côté backend.");
    }
  }
}

// Lancer uniquement la connexion
login().catch((err) => {
  console.error("Erreur globale inattendue :", err);
});
