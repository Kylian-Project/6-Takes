// models/player.js
import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Player = db.define("player", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  username: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  first_login: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  icon: {
    type: DataTypes.INTEGER,
    allowNull: false, 
    defaultValue: 0,      // by default, every player got an icon with id = 0 (gray color Icon)..
  },
  score: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  total_played: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  total_won: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  }
}, {
  tableName: "players",
  timestamps: true,
  createdAt: "created_at",
  updatedAt: false
});

export default Player;