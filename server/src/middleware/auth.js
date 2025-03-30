// middleware/auth.js
const jwt = require("jsonwebtoken");

const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader || !authHeader.startsWith("dioV ")) {
    return res.status(401).json({ message: "Token manquant ou mal formé" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id; // Le joueur connecté est maintenant dispo via req.userId
    next(); // Passe au contrôleur suivant
  } catch (err) {
    return res.status(403).json({ message: "Token invalide ou expiré" });
  }
};

module.exports = verifyToken;
