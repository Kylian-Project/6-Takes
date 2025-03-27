import express from "express";
import { Server } from "socket.io";
import rateLimit from "express-rate-limit";
import routes from "./routes";
import { myDataSource } from "./app-data-source";
import http from "http";

//////////////////////////////// import utils
import { roomHandler } from "./utils/rooms";
import { PlayGame } from "./utils/partie";
import cors from "cors";
import { authenticateToken } from "./middleware/apiKeyAuth";
import fs from "fs";
import https from "https";
import { Request, Response, NextFunction } from "express";

const app = express();
// const SERVER_PORT = process.env.SERVER_PORT;

let server;

if (process.env.DEVMODE === "True") {
    server = http.createServer(app);

    server.listen(process.env.SERVER_PORT, () => {
        console.log(`listening on ${process.env.SERVER_PORT}`);
    });
} else {
    const privateKey = fs.readFileSync(
        "/home/gitlab-runner/serverSsl/private.key",
        "utf8"
    );
    const certificate = fs.readFileSync(
        "/home/gitlab-runner/serverSsl/certificate.crt",
        "utf8"
    );

    const credentials = {
        key: privateKey,
        cert: certificate,
        rejectUnauthorized: false,
    };

    server = https.createServer(credentials, app);

    server.listen(process.env.SERVER_PORT, () => {
        console.log(`listening on ${process.env.SERVER_PORT}`);
    });
}

// middleware pour limiter le nombre de requêtes à 1000 par heure
const limiter = rateLimit({
    max: 1000,
    windowMs: 60 * 60 * 1000,
    message:
        "Trop de requêtes ont été effectuées depuis cette adresse IP. Veuillez réessayer dans une heure.",
});

app.use(limiter);

app.use(
    cors({
        origin: process.env.WEBSITE_URL,
    })
);

app.use(authenticateToken);

app.use(express.json());

export const io = new Server(server, {
    cors: { origin: process.env.WEBSITE_URL },
});

io.on("connection", (socket) => {
    console.log("a user connected", socket.id);
    roomHandler(socket, io);
    PlayGame(socket, io);
});

// connect to database
myDataSource
    .initialize()
    .then(() => {
        console.log("Database connection established");
    })
    .catch((error: any) => {
        console.error("Database connection failed: ", error);
    });

// register routes
app.use("/", routes);

app.use(function (err: any, req: Request, res: Response, next: NextFunction) {
    console.error(err.stack);
    res.status(500).send("Something broke!");
});
