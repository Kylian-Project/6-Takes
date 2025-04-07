// controllers/lobby.controller.js
import Lobby from "../models/lobby.js";

const getAllLobbies = async (req, res) => {
  try {
    const lobbies = await Lobby.findAll();
    res.status(200).json(lobbies);
  } catch (err) {
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

const deleteLobby = async (req, res) => {
  const { lobbyId } = req.params;
  try {
    const deleted = await Lobby.destroy({ where: { id: lobbyId } });
    if (!deleted) return res.status(404).json({ message: "Lobby non trouvé" });
    res.status(200).json({ message: "Lobby supprimé" });
  } catch (err) {
    res.status(500).json({ message: "Erreur serveur", error: err });
  }
};

export { getAllLobbies, deleteLobby };
