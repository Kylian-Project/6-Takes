import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Icon = db.define("icon", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  alt: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  file_path: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  }
}, {
  tableName: "icons",
  timestamps: false,
});

export default Icon;
