import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Sound = db.define("sound", {
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
  tableName: "sounds",
  timestamps: false,
});

export default Sound;
