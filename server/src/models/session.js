const { DataTypes } = require("sequelize");
const db = require("../config/db");

const Session = db.define("session", {
  id_player: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  token: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  expire_at: {
    type: DataTypes.DATE,
    allowNull: false
  }
}, {
  timestamps: false,
  tableName: "sessions"
});

module.exports = Session;
