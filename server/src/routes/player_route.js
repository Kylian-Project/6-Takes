// routes/player_route.js

import express from "express";
import {inscription,
        requestPasswordReset, verifyResetCode, resetPassword, 
        login, logout, reconnect, 
        updateProfile,
	getBanStatus
        } from "../controllers/player.controller.js";
import {verifyToken} from "../middleware/auth.js"

const router = express.Router();

// Routes d'authentification
router.post("/inscription", inscription);

router.post("/password/request", requestPasswordReset);
router.post("/password/verify", verifyResetCode);
router.post("/password/reset", resetPassword);

router.post("/connexion", login);                       
router.post("/logout", verifyToken, logout);            // protected route !important to have Token for a specific USER and not just any user 
router.post("/reconnect", verifyToken, reconnect);      // protected route !important to have Token for a specific USER and not just any user

router.post("/updateProfile", verifyToken, updateProfile);   // protected route !important to have Token for a specific USER and not just any user

// Vérifier le statut de bannissement (GET)
router.get('/ban-status/:username', getBanStatus);


// other routes gonna be added, DO NOT FORGET! 


export default router;
