// routes/player_route.js

import express from "express";
import {inscription, requestPasswordReset, verifyResetCode, resetPassword, login, logout, reconnect} from "../controllers/player.controller.js";
import {verifyToken} from "../middleware/auth.js"

const router = express.Router();

// Routes d'authentification
router.post("/inscription", inscription);

router.post("/password/request", requestPasswordReset);
router.post("/password/verify", verifyResetCode);
router.post("/password/reset", resetPassword);

router.post("/connexion", login);
router.post("/logout", verifyToken, logout);
router.post("/reconnect", verifyToken, reconnect);
// other routes gonna be added, DO NOT FORGET! 


export default router;
