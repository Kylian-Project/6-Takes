import { DataTypes } from "sequelize";
import db from "../config/db.js";

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

export default Session;
