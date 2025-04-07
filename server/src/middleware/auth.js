import jwt from "jsonwebtoken";
import Session from "../models/session.js";

/**
 * Vérifie le token pour les requêtes HTTP protégées (Express)
 */
const verifyToken = async (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader || !authHeader.startsWith(`${process.env.AUTH_HEADER_PREFIX} `)) {
    return res.status(401).json({ message: "Token manquant ou mal formé" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const session = await Session.findOne({
      where: {
        id_player: decoded.id,
        token
      }
    });

    if (!session || new Date() > session.expire_at) {
      return res.status(403).json({ message: "Session expirée ou invalide" });
    }

    req.userId = decoded.id;
    req.token = token;
    next();
  } catch (err) {
    return res.status(403).json({ message: "Token invalide ou expiré" });
  }
};

/**
 * Vérifie le token pour les connexions WebSocket (Socket.IO)
 */
const verifySocketToken = async (socket) => {
  const token = socket.handshake.query.token;

  if (!token) {
    throw new Error("Token manquant");
  }

  const decoded = jwt.verify(token, process.env.JWT_SECRET);

  const session = await Session.findOne({
    where: {
      id_player: decoded.id,
      token
    }
  });

  if (!session || new Date() > session.expire_at) {
    throw new Error("Session expirée ou invalide");
  }

  return decoded.id;
};

export { verifyToken, verifySocketToken };