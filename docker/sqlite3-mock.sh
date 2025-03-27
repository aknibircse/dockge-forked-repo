#!/bin/sh
set -e

echo "Setting up SQLite3 mock implementation..."

# Create the mock implementation directory
mkdir -p /app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-x64
mkdir -p /app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64

# Create a JavaScript mock implementation of SQLite3
cat > /app/node_modules/@louislam/sqlite3/lib/sqlite3-mock.js << 'EOL'
const EventEmitter = require('events');

// In-memory storage for tables
const tables = {
  knex_migrations: [],
  knex_migrations_lock: [{ index: 1, is_locked: 0 }] // Initialize with unlocked state
};

// Mock Database class that inherits from EventEmitter
class Database extends EventEmitter {
  constructor(filename, mode, callback) {
    super();
    console.log(`[SQLite3 Mock] Opening database: ${filename}`);
    this.filename = filename;
    
    // Call the callback if provided
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    
    // Emit open event
    process.nextTick(() => {
      this.emit('open');
    });
  }

  run(sql, params, callback) {
    console.log(`[SQLite3 Mock] Run: ${sql}`);
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    // Handle specific operations
    if (sql.includes('update `knex_migrations_lock`')) {
      // Update the lock status
      if (params && params.length >= 2) {
        const newLockValue = params[0];
        const oldLockValue = params[1];
        
        // Only update if the current value matches the expected value
        if (tables.knex_migrations_lock[0].is_locked === oldLockValue) {
          tables.knex_migrations_lock[0].is_locked = newLockValue;
          console.log(`[SQLite3 Mock] Updated migration lock to: ${newLockValue}`);
        }
      }
    } else if (sql.includes('insert into `knex_migrations_lock`')) {
      // Only insert if the table is empty
      if (tables.knex_migrations_lock.length === 0) {
        tables.knex_migrations_lock.push({ index: 1, is_locked: params[0] });
      }
    } else if (sql.includes('insert into `knex_migrations`')) {
      // Add a migration record
      const migrationId = tables.knex_migrations.length + 1;
      tables.knex_migrations.push({
        id: migrationId,
        name: params[0],
        batch: params[1],
        migration_time: new Date().toISOString()
      });
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback.call(this, null);
      });
    }
    return this;
  }

  get(sql, params, callback) {
    console.log(`[SQLite3 Mock] Get: ${sql}`);
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, {});
      });
    }
    return this;
  }

  all(sql, params, callback) {
    console.log(`[SQLite3 Mock] All: ${sql}`);
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    let result = [];
    
    // Handle specific queries
    if (sql.includes('knex_migrations_lock')) {
      result = tables.knex_migrations_lock;
    } else if (sql.includes('knex_migrations')) {
      result = tables.knex_migrations;
    } else if (sql.includes('sqlite_master')) {
      // Pretend tables exist
      if (params && params[0] === 'knex_migrations') {
        result = [{ name: 'knex_migrations', type: 'table' }];
      } else if (params && params[0] === 'knex_migrations_lock') {
        result = [{ name: 'knex_migrations_lock', type: 'table' }];
      }
    } else if (sql.includes('PRAGMA')) {
      if (sql.includes('journal_mode')) {
        result = [{ journal_mode: 'WAL' }];
      } else if (sql.includes('cache_size')) {
        result = [{ cache_size: -12000 }];
      }
    } else if (sql.includes('sqlite_version()')) {
      result = [{ 'sqlite_version()': '3.36.0' }];
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, result);
      });
    }
    return this;
  }

  each(sql, params, callback, complete) {
    console.log(`[SQLite3 Mock] Each: ${sql}`);
    if (typeof params === 'function') {
      complete = callback;
      callback = params;
      params = [];
    }
    
    if (typeof complete === 'function') {
      process.nextTick(() => {
        complete(null, 0);
      });
    }
    return this;
  }

  exec(sql, callback) {
    console.log(`[SQLite3 Mock] Exec: ${sql}`);
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    return this;
  }

  prepare(sql, params, callback) {
    console.log(`[SQLite3 Mock] Prepare: ${sql}`);
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    const statement = new Statement();
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, statement);
      });
    }
    
    return statement;
  }

  close(callback) {
    console.log('[SQLite3 Mock] Close database');
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    
    process.nextTick(() => {
      this.emit('close');
    });
    
    return this;
  }

  configure(option, value) {
    console.log(`[SQLite3 Mock] Configure: ${option} = ${value}`);
    return this;
  }

  serialize(callback) {
    console.log('[SQLite3 Mock] Serialize');
    if (typeof callback === 'function') {
      callback(this);
    }
    return this;
  }

  parallelize(callback) {
    console.log('[SQLite3 Mock] Parallelize');
    if (typeof callback === 'function') {
      callback(this);
    }
    return this;
  }
}

// Mock Statement class
class Statement extends EventEmitter {
  constructor() {
    super();
    this.sql = '';
  }

  bind(params, callback) {
    console.log('[SQLite3 Mock] Statement bind');
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    return this;
  }

  reset(callback) {
    console.log('[SQLite3 Mock] Statement reset');
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    return this;
  }

  finalize(callback) {
    console.log('[SQLite3 Mock] Statement finalize');
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    return this;
  }

  run(params, callback) {
    console.log('[SQLite3 Mock] Statement run');
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback.call(this, null);
      });
    }
    return this;
  }

  get(params, callback) {
    console.log('[SQLite3 Mock] Statement get');
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, {});
      });
    }
    return this;
  }

  all(params, callback) {
    console.log('[SQLite3 Mock] Statement all');
    if (typeof params === 'function') {
      callback = params;
      params = [];
    }
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, []);
      });
    }
    return this;
  }

  each(params, callback, complete) {
    console.log('[SQLite3 Mock] Statement each');
    if (typeof params === 'function') {
      complete = callback;
      callback = params;
      params = [];
    }
    
    if (typeof complete === 'function') {
      process.nextTick(() => {
        complete(null, 0);
      });
    }
    return this;
  }
}

// Mock Backup class
class Backup extends EventEmitter {
  constructor(source, destFilename, callback) {
    super();
    console.log(`[SQLite3 Mock] Backup to ${destFilename}`);
    
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, this);
      });
    }
  }

  step(pages, callback) {
    console.log(`[SQLite3 Mock] Backup step: ${pages} pages`);
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null, true);
      });
    }
    return this;
  }

  finish(callback) {
    console.log('[SQLite3 Mock] Backup finish');
    if (typeof callback === 'function') {
      process.nextTick(() => {
        callback(null);
      });
    }
    return this;
  }
}

// Export the mock classes
module.exports = {
  Database,
  Statement,
  Backup,
  verbose: function() {
    console.log('[SQLite3 Mock] Verbose mode enabled');
    return module.exports;
  },
  OPEN_READONLY: 1,
  OPEN_READWRITE: 2,
  OPEN_CREATE: 4,
  OPEN_FULLMUTEX: 65536,
  OPEN_URI: 64,
  OPEN_SHAREDCACHE: 131072,
  OPEN_PRIVATECACHE: 262144,
  VERSION: '5.1.6-mock',
  SOURCE_ID: '2023-05-16 12:36:15 831d0fb2836b71c9bc3392b82f8ea6813fa7dea9053e1f5a449c85bc050499ae',
  VERSION_NUMBER: 5001006,
  OK: 0,
  ERROR: 1,
  INTERNAL: 2,
  PERM: 3,
  ABORT: 4,
  BUSY: 5,
  LOCKED: 6,
  NOMEM: 7,
  READONLY: 8,
  INTERRUPT: 9,
  IOERR: 10,
  CORRUPT: 11,
  NOTFOUND: 12,
  FULL: 13,
  CANTOPEN: 14,
  PROTOCOL: 15,
  EMPTY: 16,
  SCHEMA: 17,
  TOOBIG: 18,
  CONSTRAINT: 19,
  MISMATCH: 20,
  MISUSE: 21,
  NOLFS: 22,
  AUTH: 23,
  FORMAT: 24,
  RANGE: 25,
  NOTADB: 26
};
EOL

# Create a mock node_sqlite3.node file
cat > /app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-x64/node_sqlite3.node << 'EOL'
// This is a mock file
EOL

# Create a mock node_sqlite3.node file for arm64
cat > /app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64/node_sqlite3.node << 'EOL'
// This is a mock file
EOL

# Update the main sqlite3.js file to use our mock
cat > /app/node_modules/@louislam/sqlite3/lib/sqlite3.js << 'EOL'
const mockSqlite3 = require('./sqlite3-mock.js');
module.exports = mockSqlite3;
EOL

echo "SQLite3 mock implementation setup complete"
