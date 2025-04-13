// utils/passwordResetUtils.js
import PasswordReset from "../models/password_reset.js";
import { Op } from "sequelize";

// Delete the expired 4 digits codes
const cleanOldResetCodes = async () => {
    await PasswordReset.destroy({
      where: {
        expires_at: { [Op.gt]: new Date() },
      }
    });
};

// Generate UNIQUE 4 digits code
const generateUniqueCode = async () => {
  let code;
  let exists = true;

  while (exists) {
    code = Math.floor(1000 + Math.random() * 9000).toString();

    const existing = await PasswordReset.findOne({
      where: { reset_token: code }
    });

    exists = !!existing;
  }

  return code;
};


export {cleanOldResetCodes, generateUniqueCode};