// models/player.js
const { DataTypes } = require("sequelize");
const db = require("../config/db");

const Player = db.define("Player", {
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
  // icon : to see later on..
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

module.exports = Player;
