import { RackgeServer } from "./rackge-server";
import { log } from "./log";

log.info("server", "Welcome To Rackge...!");
const server = new RackgeServer();
await server.serve();
