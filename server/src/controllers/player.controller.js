// controllers/player.controller.js
import Player from "../models/player.js";
import Session from "../models/session.js";
import jwt from "jsonwebtoken";
import PasswordReset from "../models/password_reset.js";
import { cleanOldResetCodes, generateUniqueCode } from "../utils/passwordReset.js";
import { sendResetCode } from "../utils/mailer.js";
import { Op } from "sequelize";
import bcrypt from "bcrypt";
import checkBan from "../utils/banManager.js";

// ? INSCRIPTION
const inscription = async (req, res) => {
  const { username, email, password } = req.body;

  try {
    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    const existing = await Player.findOne({ where: { email } });
    if (existing) return res.status(400).json({ message: "Cet email est déjà utilisé." });

    const existingUsername = await Player.findOne({ where: { username } });
    if (existingUsername) return res.status(400).json({ message: "Ce pseudo est déjà pris." });
    
    const newPlayer = await Player.create({ username, email, password: hashedPassword });

    res.status(200).json({ message: "Inscription réussie", player: newPlayer });
  } catch (err) {
    console.error("Erreur lors de l'inscription :", err);
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

// ? REQUEST PASSWORD RESET
const requestPasswordReset = async (req, res) => {
  const { email } = req.body;

  try {
    const player = await Player.findOne({ where: { email } });
    if (!player) return res.status(404).json({ message: "No player with this email." });

    // Supprimer toutes les lignes existantes de ce joueur
    await PasswordReset.destroy({
      where: { id_player: player.id }
    });

    // Supprimer tous les codes expir�s (optionnel, mais bien)
    await cleanOldResetCodes();

    const code = await generateUniqueCode(); // unique 4-digit code
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Cr�er un nouveau code unique pour ce joueur
    await PasswordReset.create({
      id_player: player.id,
      reset_token: code,
      expires_at: expiresAt,
      used: false
    });

    console.log(`\t\tCode envoy� � ${email} :`, code);
    await sendResetCode(email, code);

    return res.status(200).json({ message: "Reset code sent." });

  } catch (error) {
    console.error("Reset error:", error);
    return res.status(500).json({ message: "Server error." });
  }
};


// ? VERIFY CODE
const verifyResetCode = async (req, res) => {
  const { email, code } = req.body;

  try {
    const player = await Player.findOne({ where: { email } });
    if (!player) {
      return res.status(404).json({ valid: false, message: "Email inconnu." });
    }

    // Verification s'il existe dans BDD
    const reset = await PasswordReset.findOne({
      where: {
        id_player: player.id,
        reset_token: code,
        used: false,
        expires_at: { [Op.gt]: new Date() }
      }
    });

    if (!reset) {
      return res.status(400).json({ valid: false, message: "Code invalide ou expiré." });
    }

    return res.status(200).json({ valid: true });

  } catch (err) {
    console.error("Erreur dans verifyResetCode :", err);
    return res.status(500).json({ valid: false, message: "Erreur serveur" });
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
        used: false
      }
    });

    if (!reset) {
      return res.status(400).json({ message: "Invalid or expired code." });
    }

    // Update password (already hashed (normally) on #GODOT#)
    // player.password = newPassword;
    console.log("newPassword", newPassword);
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    player.password = hashedPassword;
    console.log("player.password", player.password);
    await player.save();

    // Mark code as used, to prevent reusing it
    reset.used = true;
    await reset.save();

    return res.status(200).json({ message: "Password successfully updated." });

  } catch (error) {
    console.error("Error in resetPassword:", error);
    return res.status(500).json({ message: "Internal server error." });
  }
};


// ? LOGIN
const login = async (req, res) => {
  const { username, password, device_id } = req.body;

  try {
    // V�rifier si l'utilisateur existe
    const player = await Player.findOne({ where: { username } });
    if (!player) return res.status(404).json({ message: "Utilisateur non trouv�" });

    // V�rifier si le mot de passe est correct
    // if (password !== player.password)
    //   return res.status(401).json({ message: "Mot de passe incorrect" });
    
    const passwordMatch = await bcrypt.compare(password, player.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: "Mot de passe incorrect" });
    }
    console.log(`\t\t[EXPRESS] Connexion de ${player.username} (ID ${player.id})`);

    const now = new Date();

<<<<<<< HEAD
    // Vérifier s'il existe déjà une session active pour ce joueur sur un autre appareil
    const differentDeviceSession = await Session.findOne({
      where: {
        id_player: player.id,
        device_id: { [Op.ne]: device_id }, // Appareil différent
=======
    // V�rifier s'il existe d�j� une session active pour ce joueur sur un autre appareil
    const differentDeviceSession = await Session.findOne({
      where: {
        id_player: player.id,
        device_id: { [Op.ne]: device_id }, // Appareil diff�rent
>>>>>>> develop
      }
    });


<<<<<<< HEAD
    // Refuser la connexion si une session est déjà active sur un autre appareil
=======
    // Refuser la connexion si une session est d�j� active sur un autre appareil
>>>>>>> develop
    if (differentDeviceSession) {
      return res.status(403).json({ message: "Account in use on another device !" });
    }

<<<<<<< HEAD
    // Vérifier s'il existe une session active pour le même joueur et le même appareil
    const sameDeviceSession = await Session.findOne({
      where: {
        id_player: player.id,
        device_id: device_id, // Même appareil
=======
    // V�rifier s'il existe une session active pour le m�me joueur et le m�me appareil
    const sameDeviceSession = await Session.findOne({
      where: {
        id_player: player.id,
        device_id: device_id, // M�me appareil
>>>>>>> develop
        expire_at: { [Op.gt]: now } // Session encore valide
      }
    });

<<<<<<< HEAD
    // Si une session avec le même appareil existe -> Delete
=======
    // Si une session avec le m�me appareil existe, la supprimer
>>>>>>> develop
    if (sameDeviceSession) {
      await Session.destroy({
        where: {
          id_player: player.id,
          device_id: device_id,
          expire_at: { [Op.gt]: now }
        }
      });
<<<<<<< HEAD
      console.log(` Old session pour ${player.username} sur le même appareil supprimée.`);
    }

    // Créer une nouvelle session
    const tokenDuration = 24 * 60 * 60;   // 1 jour
    const token = jwt.sign(
      { id: player.id,
        username: player.username,
        email: player.email
      },
=======
      console.log(`\t\t?? Ancienne session pour ${player.username} sur le m�me appareil supprim�e.`);
    }

    // Cr�er une nouvelle session
    const tokenDuration = 24 * 60 * 60; // 1 jour
    const token = jwt.sign(
      { id: player.id, username: player.username, email: player.email },
>>>>>>> develop
      process.env.JWT_SECRET,
      { expiresIn: tokenDuration }
    );

    const expireAt = new Date(now.getTime() + tokenDuration * 1000);

<<<<<<< HEAD
    // Enregistrer new session dans bdd
    await Session.create({
      id_player: player.id,
      token: token,
      device_id: device_id,
=======
    // Enregistrer la nouvelle session dans la base de donn�es
    await Session.create({
      id_player: player.id,
      token: token,
      device_id: device_id,  // Enregistrer l'ID de l'appareil
>>>>>>> develop
      created_at: now,
      expire_at: expireAt
    });

<<<<<<< HEAD
    console.log(`[EXPRESS] Connexion réussie : ${player.username} (ID ${player.id})\n`);
=======
    console.log(`\t\t? [EXPRESS] Connexion r�ussie : ${player.username} (ID ${player.id})`);
>>>>>>> develop

    res.status(200).json({
      message: "Connexion r�ussie",
      token,
      expire_at: expireAt,
      player: {
        id: player.id,
        username: player.username,
        email: player.email,
        icon: player.icon,
        created_at: player.created_at,
        first_login: player.first_login,
        total_played: player.total_played,
        total_won: player.total_won,
        score: player.score
      }
    });

  } catch (err) {
    console.error("Erreur lors de la connexion :", err);
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};


<<<<<<< HEAD
// ? DECONNEXION Volontairement
=======
// ? DECONNEXION Volontaire
>>>>>>> develop
const logout = async (req, res) => {
  const userId = req.userId;
  const token = req.token; // On r�cup�re le token utilis� pour la requ�te

  try {
    const deleted = await Session.destroy({
      where: {
        id_player: userId,
        token
      }
    });

    if (deleted === 0) {
      return res.status(404).json({ message: "Session non trouv�e" });
    }

    console.log(`\t\t[EXPRESS] D�connexion : ID ${userId}`);
    return res.status(200).json({ message: "D�connexion r�ussie" });

  } catch (err) {
    return res.status(500).json({ message: "Erreur lors de la d�connexion", error: err });
  }
};

// RECONNEXION w Token
const reconnect = async (req, res) => {
  const userId = req.userId;
  const token = req.token;

  console.log("\t\t🔐 [RECONNECT] ID joueur :", userId);
  console.log("\t\t🔐 [RECONNECT] Token utilisé :", token);

  try {
    const player = await Player.findByPk(userId);
    if (!player) return res.status(404).json({ message: "Joueur non trouv�" });

    return res.status(200).json({
      message: "Reconnexion r�ussie",
      player: {
        id: player.id,
        username: player.username,
        email: player.email,
        icon: player.icon,
        created_at: player.created_at,
        first_login: player.first_login,
        total_played: player.total_played,
        total_won: player.total_won,
        score: player.score
      }
    });
  } catch (err) {
    console.error("Erreur dans login :", err);
    return res.status(500).json({ message: "Erreur serveur", error: err });
  }
};


// ? UPDATE PROFIL
const updateProfile = async (req, res) => {
  const userId = req.userId;
  // Godot side not done username, password update yet, aborting.. except icon
  const { username, password, icon } = req.body;

  try {
    const player = await Player.findByPk(userId);
    if (!player) return res.status(404).json({ message: "Joueur introuvable" });
    
    // ###################################
    // ### to see later on what to add ###
    // ###################################

    if (username !== undefined && username !== "") player.username = username;

    // no need for verification normally, its the client gotta check whether old pass and new pass are the same,
    // or ever pass and confirm pass match or not... (as well as the hashing step)
    if (password !== undefined && password !== "") player.password = password;  

    if (icon !== undefined && icon !== ""){ //typeof icon === "number" && Number.isInteger(icon)) {
      console.log("\t\tReceived icon ID:", icon);
      player.icon = icon;
    }

    await player.save();

    return res.status(200).json({
      message: "Profil mis � jour !",
      player: {
        id: player.id,
        username: player.username,
        icon: player.icon,
        email: player.email,
        icon: player.icon,
        created_at: player.created_at,
        first_login: player.first_login,
        total_played: player.total_played,
        total_won: player.total_won,
        score: player.score
      }
    });
  } catch (err) {
    return res.status(500).json({ message: "Erreur lors de la mise � jour", error: err });
  }
};


// ? BAN STATUS
const getBanStatus = async(req, res) => {
    const username = req.params.username;
    console.log(`[DEBUG] Vérification du bannissement pour l'ID : ${username}`);
    try {
        // Vérifier si le joueur existe
        const player = await Player.findOne({ where: { username: username } });
        if (!player) {
            return res.status(404).json({ error: `Joueur ${username} non trouvé.` });
        }

        // Vérifier le statut de bannissement
        const banStatus = await checkBan(player.id);
        if (banStatus.banned) {
            return res.json({ isBanned: true, timeLeft: banStatus.timeLeft });
        } else {
            return res.json({ isBanned: false, timeLeft: 0 });
        }
    } catch (error) {
        console.error('Erreur lors de la vérification du bannissement :', error);
        res.status(500).json({ error: 'Erreur serveur.' });
    }
}


export { inscription, requestPasswordReset, verifyResetCode, resetPassword, login, logout, reconnect, updateProfile, getBanStatus};