const axios = require("axios");

const BASE_URL = "http://185.155.93.105:14001/api/player";

const testPlayer = {
  username: "client9Test",
  email: "client9@test.com",
  password: "azerty99"
};

async function register() {
  try {
    const res = await axios.post(`${BASE_URL}/inscription`, testPlayer);
    console.log("Inscription réussie :", res.data);
  } catch (err) {
    console.error("Erreur inscription :", err.response?.data || err.message);
  }
}

async function accessProfile(token) {
    try {
      const res = await axios.get(`${BASE_URL}/profile`, {
        headers: {
          Authorization: `dioV ${token}`
        }
      });
      console.log("Accès profil :", res.data);
    } catch (err) {
      console.error("Erreur accès profil :", err.response?.data || err.message);
    }
  }
  

async function login() {
  try {
    const res = await axios.post(`${BASE_URL}/connexion`, {
      username: testPlayer.username,
      password: testPlayer.password
    });
    console.log("Connexion réussie :", res.data);
    return res.data;
  } catch (err) {
    console.error("Erreur connexion :", err.response?.data || err.message);
  }
}

async function runTest() {
  await register();
  const loginRes = await login();
  if (loginRes?.token) {
    await accessProfile(loginRes.token);
  }
}

runTest();
