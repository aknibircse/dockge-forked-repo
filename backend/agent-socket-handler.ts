import { RackgeServer } from "./dockge-server";
import { AgentSocket } from "../common/agent-socket";
import { RackgeSocket } from "./util-server";

export abstract class AgentSocketHandler {
    abstract create(socket : RackgeSocket, server : RackgeServer, agentSocket : AgentSocket): void;
}
