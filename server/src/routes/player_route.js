// routes/player_route.js

import express from "express";
const router = express.Router();
import {inscription, login, logout} from "../controllers/player.controller.js";
import {verifyToken} from "../middleware/auth.js"

// Routes d'authentification
router.post("/inscription", inscription);
router.post("/connexion", login);
router.post("/logout", verifyToken, logout);


// other routes gonna be added, DO NOT FORGET! 

router.get("/profile", verifyToken, (req, res) => {
  res.status(200).json({
    message: "AccÃ¨s autorisÃ© au profil",
    userId: req.userId // InjectÃ© par le token JWT
  });
});

export default router;
