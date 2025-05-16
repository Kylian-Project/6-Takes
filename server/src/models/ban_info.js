import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const BanInfo = sequelize.define('ban_info', {
    player_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'players',
            key: 'id'
        }
    },
    ban_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0
    },
    last_ban: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW
    },
    ban_duration: {
        type: DataTypes.INTEGER,
        defaultValue: 0
    }
}, {
    tableName: 'ban_info',
    timestamps: false
});

export default BanInfo;