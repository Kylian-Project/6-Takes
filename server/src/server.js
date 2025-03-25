const WebSocket = require("ws");

const server = new WebSocket.Server({ port: 10001 }, () => {
    console.log("WebSocket server running 10001...");
});

server.on("connection", (socket) => {
    console.log("New client connected!");

    socket.on("message", (message) => {
        console.log("Message reçu du client:", message.toString());

        // Réponse personnalisée en fonction du message reçu
        if (message.toString().toLowerCase() === "hello") {
            socket.send("Salut, client !");
        } else {
            socket.send(`Tu as envoyé: "${message}"`);
        }
    });

    socket.on("close", () => console.log("Client déconnecté"));
    socket.on("error", (error) => console.error("Erreur serveur:", error));
});
