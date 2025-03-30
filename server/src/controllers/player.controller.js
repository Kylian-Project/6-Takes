// controllers/player.controller.js
const Player = require("../models/player");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const inscription = async (req, res) => {
  const { username, email, password } = req.body;

  try {
    const existing = await Player.findOne({ where: { email } });
    if (existing) return res.status(400).json({ message: "Cet email est déjà utilisé.." });

    const existingUsername = await Player.findOne({ where: { username } });
    if (existingUsername) return res.status(400).json({ message: "Ce Pseudo est déjà pris.." });

    // 12 cycles so that it will be hard to crack the password. (slow but secure)
    const hashedPassword = await bcrypt.hash(password, 12); 

    const newPlayer = await Player.create({
      username,
      email,
      password: hashedPassword,
      // id,
      // first_login: true,
      // score: 0,
      // total_played: 0,
      // total_won: 0,
// No need for init as its already done in DB
    });

    res.status(201).json({ message: "Inscription réussie", player: newPlayer });
  } catch (err) {
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

const login = async (req, res) => {
  const { username, password } = req.body;

  try {
    // Comparaison of entered username and password in db
    const player = await Player.findOne({ where: { username } });
    if (!player) return res.status(404).json({ message: "Utilisateur non trouvé" });

    // Comparaison of entered password and password in db
    const isValid = await bcrypt.compare(password, player.password);
    if (!isValid) return res.status(401).json({ message: "Mot de passe incorrect" });

    const token = jwt.sign({ id: player.id }, process.env.JWT_SECRET, { expiresIn: "24h" });

    //   Response for the client
    // # Modify if frontend needs anything about Player.. #
    res.status(200).json({
      message: "Connexion réussie",
      token,
      player: {
        id: player.id,
        username: player.username,
        email: player.email,
        created_at: player.created_at,
        first_login: player.first_login,
        total_played: player.total_played,
        total_won: player.total_won,
        score: player.score
      }
    });    
  } catch (err) {
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

module.exports = {
  inscription,
  login
};
