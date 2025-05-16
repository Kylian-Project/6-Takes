// utils/banManager.js
import sequelize from '../config/db.js';
import Player from '../models/player.js';

async function checkBan(playerId) {
    try {
        // Vérifier si le joueur existe
        const player = await Player.findOne({ where: { id: playerId } });
        if (!player) return { banned: false };

        // Récupérer les informations de bannissement depuis la table ban_info
        const [result] = await sequelize.query(
            `SELECT ban_duration, last_ban 
            FROM ban_info 
            WHERE player_id = ?
            ORDER BY last_ban DESC 
            LIMIT 1 ;`,
            { replacements: [playerId] });

        // Vérification du résultat de la requête SQL
        if (result && result.length > 0) {
            const { ban_duration, last_ban } = result[0];
            const banEnd = new Date(new Date(last_ban).getTime() + ban_duration * 1000);
            const now = new Date();

            // Vérifier si le ban est encore actif
            if (now < banEnd) {
                const timeLeft = Math.floor((banEnd - now) / 1000);
                return { banned: true, timeLeft };
            }
        }
        return { banned: false };
    } catch (err) {
        console.error(`Error checking ban: ${err.message}`);
        return { banned: false };
    }
}

export default checkBan;
