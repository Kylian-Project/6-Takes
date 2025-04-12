// routes/player_route.js

import express from "express";
const router = express.Router();
import {inscription, requestPasswordReset, resetPassword, login, logout, reconnect} from "../controllers/player.controller.js";
import {verifyToken} from "../middleware/auth.js"

// Routes d'authentification
router.post("/inscription", inscription);

router.post("/password/request", requestPasswordReset);
router.post("/password/reset", resetPassword);

router.post("/connexion", login);
router.post("/logout", verifyToken, logout);
router.post("/reconnect", verifyToken, reconnect);
// other routes gonna be added, DO NOT FORGET! 


export default router;
