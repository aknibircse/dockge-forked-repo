/**
 * Limit Queue
 * The first element will be removed when the length exceeds the limit
 */
export class LimitQueue extends Array {
    __limit;
    __onExceed;
    constructor(limit) {
        super();
        this.__limit = limit;
    }
    pushItem(value) {
        super.push(value);
        if (this.length > this.__limit) {
            const item = this.shift();
            if (this.__onExceed) {
                this.__onExceed(item);
            }
        }
    }
}
