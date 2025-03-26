import { RackgeServer } from "./dockge-server";
import { log } from "./log";

log.info("server", "Welcome to dockge!");
const server = new RackgeServer();
await server.serve();
