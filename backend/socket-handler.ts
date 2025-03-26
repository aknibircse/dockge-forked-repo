import { RackgeServer } from "./rackge-server";
import { RackgeSocket } from "./util-server";

export abstract class SocketHandler {
    abstract create(socket : RackgeSocket, server : RackgeServer): void;
}
