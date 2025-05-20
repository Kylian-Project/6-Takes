const { Sequelize } = require("sequelize");
require("dotenv").config();

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: "mysql",
    logging: false,
    synchronize: true,
  }
);

sequelize.authenticate()
  .then(() => console.log("Connexion réussie à la base de données"))
  .catch((err) => console.error("Erreur de connexion :", err));
