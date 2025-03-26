export class AgentSocket {
    eventList = new Map();
    on(event, callback) {
        this.eventList.set(event, callback);
    }
    call(eventName, ...args) {
        const callback = this.eventList.get(eventName);
        if (callback) {
            callback(...args);
        }
    }
}
//# sourceMappingURL=agent-socket.js.map