require("dotenv").config();
const jwt = require("jsonwebtoken");
const Session = require("../models/session");

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader || !authHeader.startsWith(`${process.env.AUTHEADER} `)) {     // verif que le authHeaderHTTP commence par ..
    return res.status(401).json({ message: "Token manquant ou mal formé" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Vérifier que le token existe bien dans la table `sessions`
    const session = await Session.findOne({
      where: {
        id_player: decoded.id,
        token: token
      }
    });

    if (!session) {
      return res.status(403).json({ message: "Session non trouvée ou invalide" });
    }

    const now = new Date();
    if (now > session.expire_at) {
      return res.status(403).json({ message: "Session expirée" });
    }

    req.userId = decoded.id;
    next(); // Tout est OK, on continue
  } catch (err) {
    return res.status(403).json({ message: "Token invalide ou expiré", error: err });
  }
};

module.exports = verifyToken;
