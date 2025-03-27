import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
    // Check if the table exists first
    const tableExists = await knex.schema.hasTable("setting");
    
    if (!tableExists) {
        return knex.schema.createTable("setting", (table) => {
            table.increments("id").primary();
            table.string("key", 200).notNullable().unique().collate("utf8_general_ci");
            table.text("value").nullable();
            table.string("type", 20).notNullable().defaultTo("string");
        });
    }
    
    // Table already exists, migration is successful
    return Promise.resolve();
}

export async function down(knex: Knex): Promise<void> {
    return knex.schema.dropTable("setting");
}
