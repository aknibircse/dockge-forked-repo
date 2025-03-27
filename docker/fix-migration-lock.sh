#!/bin/sh
set -e

echo "Fixing database migration lock..."

# Create the data directory if it doesn't exist
mkdir -p /app/data

# Check if the database file exists
if [ -f "/app/data/rackge.db" ]; then
  echo "Database file found, attempting to fix migration lock..."
  
  # Try to unlock the migrations table using SQLite CLI
  if command -v sqlite3 >/dev/null 2>&1; then
    echo "Using sqlite3 CLI to fix migration lock..."
    sqlite3 /app/data/rackge.db "UPDATE knex_migrations_lock SET is_locked = 0 WHERE is_locked = 1;"
    echo "Migration lock fixed via SQLite CLI"
  else
    echo "SQLite CLI not available, creating a Node.js script to fix the lock..."
    
    # Create a temporary Node.js script to fix the lock
    cat > /tmp/fix-lock.js << 'EOL'
const fs = require('fs');
const path = require('path');

// Check if we're using the mock implementation
const isMock = process.env.NODE_PTY_MOCK === 'true';

if (isMock) {
  console.log('Using mock implementation, creating empty migration tables...');
  
  // Create mock migration tables in our mock implementation
  try {
    // This will be picked up by our mock implementation
    process.env.UNLOCK_MIGRATIONS = 'true';
    console.log('Set UNLOCK_MIGRATIONS=true for mock implementation');
  } catch (err) {
    console.error('Error setting up mock migration fix:', err);
  }
} else {
  // Try to use the actual SQLite module
  try {
    const dbPath = path.join('/app/data', 'rackge.db');
    console.log(`Attempting to fix migration lock in: ${dbPath}`);
    
    // Only proceed if the database file exists
    if (fs.existsSync(dbPath)) {
      const sqlite3 = require('@louislam/sqlite3').verbose();
      const db = new sqlite3.Database(dbPath);
      
      // First check if the table exists
      db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='knex_migrations_lock'", (err, row) => {
        if (err) {
          console.error('Error checking for migrations lock table:', err);
          db.close();
          return;
        }
        
        if (row) {
          // Table exists, update the lock
          db.run("UPDATE knex_migrations_lock SET is_locked = 0 WHERE is_locked = 1", function(err) {
            if (err) {
              console.error('Error updating migration lock:', err);
            } else {
              console.log(`Migration lock fixed. Changes: ${this.changes}`);
            }
            db.close();
          });
        } else {
          // Table doesn't exist, create it
          db.serialize(() => {
            db.run("CREATE TABLE IF NOT EXISTS knex_migrations_lock (index INTEGER PRIMARY KEY, is_locked INTEGER)");
            db.run("INSERT INTO knex_migrations_lock (index, is_locked) VALUES (1, 0)");
            console.log('Created new migrations lock table with unlocked state');
            db.close();
          });
        }
      });
    } else {
      console.log('Database file does not exist yet, no need to fix migration lock');
    }
  } catch (err) {
    console.error('Error fixing migration lock:', err);
  }
}
EOL
    
    # Run the Node.js script
    node /tmp/fix-lock.js
    rm -f /tmp/fix-lock.js
  fi
else
  echo "Database file does not exist yet, no need to fix migration lock"
fi

# Update our SQLite3 mock to handle migration locks properly
if [ -f "/app/node_modules/@louislam/sqlite3/lib/sqlite3-mock.js" ]; then
  echo "Updating SQLite3 mock to handle migration locks properly..."
  
  # Add environment variable handling for migration lock
  cat >> /app/node_modules/@louislam/sqlite3/lib/sqlite3-mock.js << 'EOL'

// Check if we need to unlock migrations
if (process.env.UNLOCK_MIGRATIONS === 'true') {
  console.log('[SQLite3 Mock] Unlocking migrations as requested by environment variable');
  tables.knex_migrations_lock = [{ index: 1, is_locked: 0 }];
}
EOL
  
  echo "SQLite3 mock updated"
fi

echo "Database migration lock fix complete"
