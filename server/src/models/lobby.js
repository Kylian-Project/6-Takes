// models/lobby.js
import { DataTypes } from "sequelize";
import db from "../config/db.js";

const Lobby = db.define("lobby", {

  // No need for id as its a Pkey and AutoIncremented in DB
  
  id_creator: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true
  },
  state: {
    type: DataTypes.ENUM("PUBLIC", "PRIVATE"),
    allowNull: false
  }
}, {
  timestamps: true,     //createdAt && expireAt
  tableName: "lobbies"
});

export default Lobby;
