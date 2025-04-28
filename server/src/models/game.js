import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Game = db.define("game", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  id_lobby: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  id_winner: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: "in_progress",
  },
  started_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  finished_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  final_global_score: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  current_round: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  current_status: {
    type: DataTypes.JSON,
    allowNull: false,
  }
}, {
  tableName: "games",
  timestamps: false,
});

export default Game;
