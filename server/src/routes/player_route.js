// routes/player_route.js
const express = require("express");
const router = express.Router();
const { inscription, login } = require("../controllers/player.controller");
const verifyToken = require("../middleware/auth");

// Routes d'authentification
router.post("/inscription", inscription);
router.post("/connexion", login);


// other routes gonna be added, DO NOT FORGET! 
router.get("/profile", verifyToken, (req, res) => {
    res.status(200).json({
      message: "Accès autorisé au profil..",
      userId: req.userId // Injecté par le token JWT
    });
  });


module.exports = router;
