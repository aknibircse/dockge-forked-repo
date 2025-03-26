import { Router } from "../router";
import express from "express";
export class MainRouter extends Router {
    create(app, server) {
        const router = express.Router();
        router.get("/", (req, res) => {
            res.send(server.indexHTML);
        });
        // Robots.txt
        router.get("/robots.txt", async (_request, response) => {
            let txt = "User-agent: *\nDisallow: /";
            response.setHeader("Content-Type", "text/plain");
            response.send(txt);
        });
        return router;
    }
}
