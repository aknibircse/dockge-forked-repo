import { SocketHandler } from "../socket-handler.js";
import { log } from "../log";
import { callbackError, callbackResult, checkLogin } from "../util-server";
export class ManageAgentSocketHandler extends SocketHandler {
    create(socket, server) {
        // addAgent
        socket.on("addAgent", async (requestData, callback) => {
            try {
                log.debug("manage-agent-socket-handler", "addAgent");
                checkLogin(socket);
                if (typeof (requestData) !== "object") {
                    throw new Error("Data must be an object");
                }
                let data = requestData;
                let manager = socket.instanceManager;
                await manager.test(data.url, data.username, data.password);
                await manager.add(data.url, data.username, data.password);
                // connect to the agent
                manager.connect(data.url, data.username, data.password);
                // Refresh another sockets
                // It is a bit difficult to control another browser sessions to connect/disconnect agents, so force them to refresh the page will be easier.
                server.disconnectAllSocketClients(undefined, socket.id);
                manager.sendAgentList();
                callbackResult({
                    ok: true,
                    msg: "agentAddedSuccessfully",
                    msgi18n: true,
                }, callback);
            }
            catch (e) {
                callbackError(e, callback);
            }
        });
        // removeAgent
        socket.on("removeAgent", async (url, callback) => {
            try {
                log.debug("manage-agent-socket-handler", "removeAgent");
                checkLogin(socket);
                if (typeof (url) !== "string") {
                    throw new Error("URL must be a string");
                }
                let manager = socket.instanceManager;
                await manager.remove(url);
                server.disconnectAllSocketClients(undefined, socket.id);
                manager.sendAgentList();
                callbackResult({
                    ok: true,
                    msg: "agentRemovedSuccessfully",
                    msgi18n: true,
                }, callback);
            }
            catch (e) {
                callbackError(e, callback);
            }
        });
    }
}
