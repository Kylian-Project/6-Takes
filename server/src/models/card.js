import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Card = db.define("card", {
  card_number: {
    type: DataTypes.INTEGER,
    primaryKey: true,
  },
  heads: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  file_path: {
    type: DataTypes.STRING,
    allowNull: false,
  }
}, {
  tableName: "cards",
  timestamps: false,
});

export default Card;
