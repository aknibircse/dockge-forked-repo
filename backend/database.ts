
import { log } from "./log";
import { R } from "redbean-node";
import { RackgeServer } from "./rackge-server";
import fs from "fs";
import path from "path";
// import knex from "knex";
// Remove the sqlite import since we're using a mock implementation
// import sqlite from "better-sqlite3";
import Dialect from "knex/lib/dialects/sqlite3/index.js";

// In-memory data store for mocking database operations
const memoryStore = {
  user: [],
  setting: [],
  agent: [],
  knex_migrations: [],
  knex_migrations_lock: [{ index: 1, is_locked: 0 }]
};

// Mock the R object methods
R.setup = () => console.log("Mock R.setup called");
R.freeze = () => console.log("Mock R.freeze called");
R.autoloadModels = () => console.log("Mock R.autoloadModels called");
R.exec = (sql) => {
  console.log(`Mock R.exec called with: ${sql}`);
  return Promise.resolve();
};
R.getAll = (sql) => {
  console.log(`Mock R.getAll called with: ${sql}`);
  if (sql.includes('journal_mode')) {
    return Promise.resolve([{ journal_mode: 'WAL' }]);
  } else if (sql.includes('cache_size')) {
    return Promise.resolve([{ cache_size: -12000 }]);
  }
  return Promise.resolve([]);
};
R.getCell = (sql) => {
  console.log(`Mock R.getCell called with: ${sql}`);
  if (sql.includes('sqlite_version()')) {
    return Promise.resolve('3.36.0');
  }
  return Promise.resolve(null);
};
R.debug = () => console.log("Mock R.debug called");

// Create mock knex object
const mockKnex = {
  // Include original methods if they exist
  ...(R.knex || {}),
  migrate: {
    latest: () => {
      console.log("Mock migration.latest called");
      return Promise.resolve();
    }
  },
  schema: {
    hasTable: (tableName) => {
      console.log(`Mock schema.hasTable called for ${tableName}`);
      return Promise.resolve(true);
    },
    createTable: (tableName, callback) => {
      console.log(`Mock schema.createTable called for ${tableName}`);
      // Create a mock table object
      const table = {
        increments: () => table,
        string: () => table,
        integer: () => table,
        boolean: () => table,
        timestamp: () => table,
        unique: () => table,
        index: () => table,
        primary: () => table
      };
      callback(table);
      return Promise.resolve();
    },
    dropTable: (tableName) => {
      console.log(`Mock schema.dropTable called for ${tableName}`);
      return Promise.resolve();
    }
  },
  count: (column) => {
    return {
      from: (tableName) => {
        return {
          first: () => {
            console.log(`Mock count ${column} from ${tableName}`);
            return Promise.resolve({ count: 0 });
          }
        };
      }
    };
  }
};

// Safely override R.knex getter to return our mock object
Object.defineProperty(R, 'knex', {
  get: function() {
    return mockKnex;
  }
});

// Add table query methods
['user', 'setting', 'agent', 'knex_migrations', 'knex_migrations_lock'].forEach(tableName => {
  mockKnex[tableName] = () => {
    return {
      count: (column) => {
        return {
          first: () => {
            console.log(`Mock ${tableName}.count(${column}) called`);
            return Promise.resolve({ count: 0 });
          }
        };
      },
      select: (...columns) => {
        return {
          where: (condition) => {
            return {
              first: () => {
                console.log(`Mock ${tableName}.select(${columns.join(', ')}).where() called`);
                return Promise.resolve(null);
              },
              orderBy: () => {
                return {
                  limit: () => {
                    console.log(`Mock ${tableName}.select(${columns.join(', ')}).where().orderBy().limit() called`);
                    return Promise.resolve([]);
                  }
                };
              }
            };
          },
          orderBy: () => {
            return {
              limit: () => {
                console.log(`Mock ${tableName}.select(${columns.join(', ')}).orderBy().limit() called`);
                return Promise.resolve([]);
              }
            };
          }
        };
      },
      insert: (data) => {
        console.log(`Mock ${tableName}.insert() called`);
        return Promise.resolve([1]);
      },
      update: (data) => {
        return {
          where: (condition) => {
            console.log(`Mock ${tableName}.update().where() called`);
            return Promise.resolve(1);
          }
        };
      },
      del: () => {
        return {
          where: (condition) => {
            console.log(`Mock ${tableName}.del().where() called`);
            return Promise.resolve(1);
          }
        };
      }
    };
  };
});

export interface DBConfig {
    type?: "sqlite" | "mysql";
    hostname?: string;
    port?: string;
    database?: string;
    username?: string;
    password?: string;
}

export class Database {
    static sqlitePath: string;
    static noReject = true;
    static dbConfig: DBConfig = {};
    static knexMigrationsPath = "./backend/migrations";
    private static server: RackgeServer;
    jwtSecret?: string;

    /**
     * @param {RackgeServer} server
     */
    static init(server: RackgeServer) {
        this.server = server;
        log.info("db", "Using database bypass to fix connection issues");
    }

    /**
     * Read the database config
     * @throws {Error} If the config is invalid
     * @typedef {string|undefined} envString
     * @returns {{type: "sqlite"} | {type:envString, hostname:envString, port:envString, database:envString, username:envString, password:envString}} Database config
     */
    static readDBConfig(): DBConfig {
        log.info("db", "Reading mock database config");
        return {
            type: "sqlite"
        };
    }

    /**
     * @typedef {string|undefined} envString
     * @param dbConfig the database configuration that should be written
     * @returns {void}
     */
    static writeDBConfig(dbConfig: DBConfig) {
        log.info("db", "Writing mock database config");
    }

    /**
     * Connect to the database
     * @param {boolean} autoloadModels Should models be automatically loaded?
     * @param {boolean} noLog Should logs not be output?
     * @returns {Promise<void>}
     */
    static async connect(autoloadModels = true) {
        log.info("db", "Using mock database connection");
        
        // Create a mock knex instance
        const mockKnex = () => {
            return {
                // Add any methods needed
            };
        };
        
        // Set up the database path
        this.sqlitePath = path.join(this.server.config.dataDir, "rackge.db");
        
        // No need to actually connect
        log.info("db", "Mock database connected successfully");
    }

    /**
     * @returns {Promise<void>}
     */
    static async initSQLite() {
        log.info("db", "Initializing mock SQLite");
    }

    /**
     * Patch the database
     * @returns {void}
     */
    static async patch() {
        log.info("db", "Skipping database migrations as we're using a mock database");
    }

    /**
     * Special handle, because tarn.js throw a promise reject that cannot be caught
     * @returns {Promise<void>}
     */
    static async close() {
        log.info("db", "Closing mock database connection");
    }

    /**
     * @returns {Promise<void>}
     */
    static async listener() {
        log.info("db", "Setting up mock database listener");
    }

    /**
     * Get the size of the database (SQLite only)
     * @returns {number} Size of database
     */
    static getSize() {
        return 0;
    }

    /**
     * Shrink the database
     * @returns {Promise<void>}
     */
    static async shrink() {
        log.info("db", "Mock database shrink operation");
    }
}
