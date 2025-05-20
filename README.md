<a name="readme-top"></a>

<div align="center">

# 🎲 6 Takes!

**An online multiplayer card game combining strategy, speed, and fun! Play with friends or solo against bots – available on PC and Web!**

![Game Logo](https://i.imgur.com/nCQF9ws.png)

</div>

---

## 📃 Table of Contents

- [📌 About the Project](#-about-the-project)
- [⭐️ Features](#️-features)
- [🛠 Tech Stack](#-tech-stack)
- [🚀 Installation & Setup](#-installation--setup)
  - [⚙️ Server Configuration](#️-server-configuration)
  - [🎮 Client Launch (Godot)](#-client-launch-godot)
- [🌐 Web Version](#-web-version)
- [👥 Project Team](#-project-team)
- [🔑 License](#-license)

---

## 📌 About the Project

**6 Takes!** is a faithful digital adaptation of the popular card game "6 qui prend!". Developed as a university project, it offers a **real-time online experience**, as well as a **solo mode with bots**, a responsive interface, and complete game logic.  
The architecture is **client-server**, fully open-source, and designed with scalability and cross-platform deployment in mind.

---

## ⭐️ Features

- 🎮 **Online Multiplayer** with public/private lobby system
- 👤 **Account System** with persistent sessions via JWT tokens
- 🤖 **Singleplayer Mode** with AI-controlled opponents
- 🧠 **Full Game Logic** (official rules: 6-card rows, penalties, rounds)
- 💬 **User-Friendly UI**: animations, accessibility features, sound feedback
- 🌐 **Web Export**: Play directly from your browser (HTML5)
- 📨 **Feedback Form** linked to Discord via bot integration

---

## 🛠 Tech Stack

| Component        | Technology Used             |
|------------------|-----------------------------|
| 🎮 **Client**    | [Godot Engine](https://godotengine.org/) (GDScript, PC/Web exports) |
| 🔌 **Server**    | Node.js + Socket.IO + Express |
| 🗃 **Database**  | MySQL + Sequelize ORM        |
| 🌍 **Hosting**   | OVH server (NGINX + HTTPS)   |
| 🎨 **UI/Design** | Figma + Godot + Photoshop    |
| 📬 **Discord Bot** | Webhook integration for feedback |
| 🔐 **Security**  | JWT Tokens, password hashing, HTTPS |

---

## 🚀 Installation & Setup

### ⚙️ Server Configuration

```bash
# Clone the server repo
git clone https://git.unistra.fr/kylian.gerard/6-qui-prend-pji-3a.git
cd server

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Then edit .env to set DB info, port, etc.

# Start the server
node server
```

> ⚠️ Make sure your MySQL server is set up and reachable, and SSL certificates are in place for production (HTTPS).

---

### 🎮 Client Launch (Godot)

```bash
# Clone the client repo
git clone https://git.unistra.fr/kylian.gerard/6-qui-prend-pji-3a.git
cd client

# Open with Godot (v4.x recommended)
godot .

# You can export the project to HTML5, Windows, Linux.
```

---

## 🌐 Web Version

You can play the game directly online via our hosted site:

👉 [https://6takes.fr/](https://6takes.fr/)

- No installation needed  
- PC, tablet, and mobile friendly  
- Play as guest or with an account  

---

## 👥 Project Team

| Name                     | Main Role                                      |
|--------------------------|------------------------------------------------|
| [Kylian GERARD](https://git.unistra.fr/kylian.gerard)       | 👑 Project Manager, website, deployment, integration |
| [Omer Ali ARMAGAN](https://git.unistra.fr/armagan)          | 🧠 Backend API & Game Logic (Node.js + Godot)         |
| [Mamadou Mouctar BAH](https://git.unistra.fr/bahmm)         | 🎮 Solo Mode & Client Support                         |
| [Lounas CHIKHI](https://git.unistra.fr/lounas.chikhi)       | ⚙️ WebSocket, bots, game logic (Node.js)                  |
| [Darren DELGADO](https://git.unistra.fr/ddelgado)           | 🎨 Visual Design, mascot, UI, animations                 |
| [Neila KRIKA](https://git.unistra.fr/nkrika)                | 🗃 Database, Godot logic, multiplayer logic            |
| [Elie ANTONIOS](https://git.unistra.fr/antonios)            | 🎛 Menus, trailer, accessibility                   |

---

## 🔑 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

💬 *Found a bug or want to suggest a feature? Reach out via our [website](https://6takes.fr/) or open an issue on Git.*
