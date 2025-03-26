export async function up(knex) {
    return knex.schema.createTable("setting", (table) => {
        table.increments("id");
        table.string("key", 200).notNullable().unique().collate("utf8_general_ci");
        table.text("value");
        table.string("type", 20);
    });
}
export async function down(knex) {
    return knex.schema.dropTable("setting");
}
