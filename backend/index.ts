import { RackgeServer } from "./rackge-server";
import { log } from "./log";

log.info("server", "Welcome to rackge!");
const server = new RackgeServer();
await server.serve();
