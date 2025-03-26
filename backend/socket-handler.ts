import { RackgeServer } from "./dockge-server";
import { RackgeSocket } from "./util-server";

export abstract class SocketHandler {
    abstract create(socket : RackgeSocket, server : RackgeServer): void;
}
