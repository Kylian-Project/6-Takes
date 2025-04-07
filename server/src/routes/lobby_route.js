// routes/lobby_route.js
import express from "express";
import { createLobby, joinLobby, leaveLobby, getLobbyUsers } from "../controllers/lobby.controller.js";
import { verifyToken } from "../middleware/auth.js";

const router = express.Router();

router.post("/create", verifyToken, createLobby);
router.post("/join", verifyToken, joinLobby);
router.post("/leave", verifyToken, leaveLobby);
router.get("/users/:lobbyId", verifyToken, getLobbyUsers);
// other routes gonna be added, DO NOT FORGET! depends on Godot implementation...

export default router;

