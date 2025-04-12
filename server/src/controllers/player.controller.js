// controllers/player.controller.js
import Player from "../models/player.js";
import Session from "../models/session.js";
import jwt from "jsonwebtoken";
import PasswordReset from "../models/password_reset.js";
import { cleanOldResetCodes, generateUniqueCode } from "../utils/passwordResetUtils.js";
import { Op } from "sequelize";

// ? INSCRIPTION
const inscription = async (req, res) => {
  const { username, email, password } = req.body;

  try {
    const existing = await Player.findOne({ where: { email } });
    if (existing) return res.status(400).json({ message: "Cet email est déjà utilisé." });

    const existingUsername = await Player.findOne({ where: { username } });
    if (existingUsername) return res.status(400).json({ message: "Ce pseudo est déjà pris." });

    const newPlayer = await Player.create({ username, email, password });

    res.status(200).json({ message: "Inscription réussie", player: newPlayer });
  } catch (err) {
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

// ? REQUEST PASSWORD RESET
const requestPasswordReset = async (req, res) => {
  const { email } = req.body;

  try {
    const player = await Player.findOne({ where: { email } });
    if (!player) return res.status(404).json({ message: "No player with this email." });
    
    // Delete expired codes
    await cleanOldResetCodes();

    const code = await generateUniqueCode(); // 4 digits code WHICH doesn't exist in DB
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins

    await PasswordReset.create({
      id_player: player.id,
      reset_token: code,
      expires_at: expiresAt,
      used: false
    });

    console.log(`📨 Code sent to ${email}:`, code);
    // Later: send this code via email

    return res.status(200).json({ message: "Reset code sent." });

  } catch (error) {
    console.error("Reset error:", error);
    return res.status(500).json({ message: "Server error." });
  }
};

// ? PASSWORD RESET
const resetPassword = async (req, res) => {
  const { email, code, newPassword } = req.body;

  try {
    // If the email exists or not ...
    const player = await Player.findOne({ where: { email } });
    if (!player) {
      return res.status(404).json({ message: "User not found." });
    }

    // If reset code exists and is valid
    const reset = await PasswordReset.findOne({
      where: {
        id_player: player.id,
        reset_token: code,
        used: false,
        expires_at: { [Op.gt]: new Date() }
      }
    });

    if (!reset) {
      return res.status(400).json({ message: "Invalid or expired code." });
    }

    // Update password (already hashed (normally) on #GODOT#)
    player.password = newPassword;
    await player.save();

    // Mark code as used, to prevent reusing it
    reset.used = true;
    await reset.save();

    return res.status(200).json({ message: "Password successfully updated." });

  } catch (error) {
    console.error("❌ Error in resetPassword:", error);
    return res.status(500).json({ message: "Internal server error." });
  }
};


// ? CONNEXION
const login = async (req, res) => {
  const { username, password } = req.body;

  try {
    const player = await Player.findOne({ where: { username } });
    if (!player) return res.status(404).json({ message: "Utilisateur non trouvé" });

    if (password !== player.password)
      return res.status(401).json({ message: "Mot de passe incorrect" });

    const now = new Date();

    // Réutiliser une session encore valide
    const existingSession = await Session.findOne({
      where: {
        id_player: player.id,
        expire_at: { [Op.gt]: now }
      }
    });

    if (existingSession) {
      console.log(`? [EXPRESS] Connexion réussie : ${player.username} (ID ${player.id})`);
      return res.status(200).json({
        message: "Connexion réussie (session existante)",
        token: existingSession.token,
        expire_at: existingSession.expire_at,
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
    }

    // Supprimer sessions expirées
    await Session.destroy({
      where: {
        id_player: player.id,
        expire_at: { [Op.lte]: now }
      }
    });

    // Créer une nouvelle session
    const tokenDuration = 24 * 60 * 60;   // 1 jour
    const token = jwt.sign(
      { id: player.id, 
        username: player.username,
        email: player.email
      },
      process.env.JWT_SECRET,
      { expiresIn: tokenDuration }
    );

    const expireAt = new Date(now.getTime() + tokenDuration * 1000);

    await Session.create({
      id_player: player.id,
      token,
      created_at: now,
      expire_at: expireAt
    });

    console.log(`? [EXPRESS] Connexion réussie : ${player.username} (ID ${player.id})\n`);
    console.log(`🔐 Token généré pour ${player.username} (ID ${player.id}) : ${token}`);

    res.status(200).json({
      message: "Connexion réussie",
      token,
      expire_at: expireAt,
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

// ? DECONNEXION Volontairement
const logout = async (req, res) => {
  const userId = req.userId;
  const token = req.token; // On récupère le token utilisé pour la requête

  try {
    const deleted = await Session.destroy({
      where: {
        id_player: userId,
        token
      }
    });

    if (deleted === 0) {
      return res.status(404).json({ message: "Session non trouvée" });
    }

    console.log(`[EXPRESS] Déconnexion : ID ${userId}`);
    return res.status(200).json({ message: "Déconnexion réussie" });

  } catch (err) {
    return res.status(500).json({ message: "Erreur lors de la déconnexion", error: err });
  }
};

// RECONNEXION w Token
const reconnect = async (req, res) => {
  const userId = req.userId;

  try {
    const player = await Player.findByPk(userId);
    if (!player) return res.status(404).json({ message: "Joueur non trouvé" });

    return res.status(200).json({
      message: "Reconnexion réussie",
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
    console.error("❌ Erreur dans login :", err);
    return res.status(500).json({ message: "Erreur serveur", error: err });
  }
};


export { inscription, requestPasswordReset, resetPassword, login, logout, reconnect };
