import { DataTypes } from "sequelize";
import db from "../config/db.js";

const LobbyParameters = db.define("lobby_parameter", {
  id_lobby: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
  code: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  nb_players: {
    type: DataTypes.INTEGER,
    defaultValue: 10,
  },
  nb_bots: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  max_points: {
    type: DataTypes.INTEGER,
    defaultValue: 66,
  },
  max_rounds: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  timer: {
    type: DataTypes.INTEGER,
    defaultValue: 30,
  },
  nb_cards: {
    type: DataTypes.INTEGER,
    defaultValue: 10,
  },
  sound: {
    type: DataTypes.INTEGER,
    allowNull: true,
  }
}, {
  tableName: "lobby_parameters",
  timestamps: false,
});

export default LobbyParameters;
