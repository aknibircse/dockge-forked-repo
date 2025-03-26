import { BeanModel } from "redbean-node/dist/bean-model";
import { R } from "redbean-node";
export class Agent extends BeanModel {
    static async getAgentList() {
        let list = await R.findAll("agent");
        let result = {};
        for (let agent of list) {
            result[agent.endpoint] = agent;
        }
        return result;
    }
    get endpoint() {
        let obj = new URL(this.url);
        return obj.host;
    }
    toJSON() {
        return {
            url: this.url,
            username: this.username,
            endpoint: this.endpoint,
        };
    }
}
export default Agent;
