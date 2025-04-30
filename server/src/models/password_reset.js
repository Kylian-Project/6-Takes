import { DataTypes } from "sequelize";
import db from "../config/db.js";

const PasswordReset = db.define("password_reset", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  id_player: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  reset_token: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  used: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  }
}, {
  tableName: "password_reset",
  timestamps: false,
});

export default PasswordReset;
