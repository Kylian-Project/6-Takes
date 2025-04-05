import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Lobby = db.define("lobby", {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  id_creator: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  state: {
    type: DataTypes.ENUM("PUBLIC", "PRIVATE"),
    allowNull: false
  }
}, {
  timestamps: false,
  tableName: "lobbies"
});

export default Lobby;
