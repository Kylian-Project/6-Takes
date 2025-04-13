import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/**
 * Envoie un code de reinitialisation style par email
 * @param {string} email - adresse du joueur
 * @param {string} code - code à 4 chiffres
 */
export const sendResetCode = async (email, code) => {
  const mailOptions = {
    from: `" 6 Takes! SUPPORT" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: "Code de reinitialisation de votre compte",
    html: `
    <div style="font-family: Arial, sans-serif; background: #f8f8f8; padding: 30px; text-align: center;">
      <div style="max-width: 500px; margin: auto; background: white; border-radius: 10px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
        <img src="https://imgur.com/a/3WJlE9d" alt="6 Takes Logo" width="120" style="margin-bottom: 20px;" />

        <h2 style="color: #D22B2B;">Reinitialisation de mot de passe</h2>
        <p>Bonjour !</p>
        <p>Tu as demande à reinitialiser ton mot de passe pour ton compte sur <strong>6 Takes!</strong></p>

        <p>Voici ton code :</p>
        <h1 style="letter-spacing: 8px; font-size: 36px; margin: 20px 0; color: #222;">${code}</h1>

        <p style="margin-top: 0;">Ce code est <strong>valide pendant 10 minutes</strong>.</p>

        <hr style="margin: 30px 0;" />

        <p style="font-size: 14px; color: #999;">
          Si tu n'as pas demande ce changement, ignore simplement ce message.
        </p>
      </div>
    </div>
    `,
  };

  try {
    const result = await transporter.sendMail(mailOptions);
    console.log("Mail envoyé :", result.response);
  } catch (err) {
    console.error("Erreur d'envoi d'email :", err);
  }

  await transporter.sendMail(mailOptions);
};
