// Import informations database

const Player = {
    async create({ username, email, passwordHash }) {
      const [result] = await db.query(
        `INSERT INTO players 
          (username, email, password, first_login, score, total_played, total_won, created_at) 
         VALUES (?, ?, ?, NULL, 0, 0, 0, NOW())`,
        [username, email, passwordHash]
      );
      return result.insertId;
    },
  
    async findByUsername(username) {
      const [rows] = await db.query(
        `SELECT * FROM players WHERE username = ?`,
        [username]
      );
      return rows[0];
    },
  
    async findByEmail(email) {
      const [rows] = await db.query(
        `SELECT * FROM players WHERE email = ?`,
        [email]
      );
      return rows[0];
    }
  };
  
  module.exports = Player;