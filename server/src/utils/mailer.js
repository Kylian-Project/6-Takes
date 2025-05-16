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
 * Sends a password reset code via email
 * @param {string} email - player's email address
 * @param {string} code - 4-digit code
 */
export const sendResetCode = async (email, code) => {
  const mailOptions = {
    from: `" 6 Takes! SUPPORT" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: "Password reset code for your account",
    html: `
    <div style="font-family: Arial, sans-serif; background: #f8f8f8; padding: 30px; text-align: center;">
      <div style="max-width: 500px; margin: auto; background: white; border-radius: 10px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1);">
        <img src="https://i.imgur.com/Qclckjg.png" alt="6 Takes Logo" width="120" style="margin-bottom: 20px;" />

        <h2 style="color: #D22B2B;">Password Reset</h2>
        <p>Hello !</p>
        <p>You have requested to reset your password for your account on <strong>6 Takes!</strong></p>

        <p>Here is your code:</p>
        <h1 style="letter-spacing: 8px; font-size: 36px; margin: 20px 0; color: #222;">${code}</h1>

        <p style="margin-top: 0;">This code is <strong>valid for 10 minutes</strong>.</p>

        <hr style="margin: 30px 0;" />

        <p style="font-size: 14px; color: #999;">
          If you did not request this change, simply ignore this message.
        </p>
      </div>
    </div>
    `,
  };

  try {
    const result = await transporter.sendMail(mailOptions);
    console.log("Email sent : ", result.response);
  } catch (err) {
    console.error("Erreur sending email : ", err);
  }

  await transporter.sendMail(mailOptions);
};
