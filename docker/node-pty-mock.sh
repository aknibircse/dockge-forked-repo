#!/bin/sh
# This script creates mock implementations for native modules
# to be used in environments where building native modules is problematic

# Set up node-pty mock
if [ "$NODE_PTY_MOCK" = "true" ]; then
  echo "Setting up node-pty mock implementation..."
  
  # Create directory for mock implementation
  mkdir -p /app/node-pty-mock
  
  # Create the mock implementation file
  cat > /app/node-pty-mock/index.js << 'EOF'
console.log("Using enhanced node-pty mock implementation");
const EventEmitter = require('events');
const { exec } = require('child_process');
const os = require('os');
const path = require('path');

/**
 * Enhanced mock implementation of node-pty
 * Provides basic terminal functionality including:
 * - Command history
 * - Special key handling
 * - Event emission
 * - Basic command execution
 */
class PtyProcess extends EventEmitter {
  constructor(file, args, options) {
    super();
    this.file = file;
    this.args = args;
    this.options = options || {};
    this.pid = Math.floor(Math.random() * 10000);
    this.cols = options?.cols || 80;
    this.rows = options?.rows || 24;
    this.process = file;
    this.running = true;
    this.commandHistory = [];
    this.historyIndex = -1;
    this.currentCommand = '';
    this.cursorPosition = 0;
    
    // Send initial prompt
    setTimeout(() => {
      this.emitData(this.getPrompt());
    }, 50);
  }

  write(data) {
    if (!this.running) return;
    
    // Handle special keys
    if (data === '\u0003') { // Ctrl+C
      this.emitData('^C\r\n' + this.getPrompt());
      this.currentCommand = '';
      this.cursorPosition = 0;
      return;
    }
    
    if (data === '\r' || data === '\n') { // Enter/Return
      this.emitData('\r\n');
      
      if (this.currentCommand.trim().length > 0) {
        // Add to history if not empty
        this.commandHistory.unshift(this.currentCommand);
        if (this.commandHistory.length > 100) {
          this.commandHistory.pop();
        }
        
        // Execute the command
        this.executeCommand(this.currentCommand);
      } else {
        // Empty command, just show prompt
        this.emitData(this.getPrompt());
      }
      
      this.currentCommand = '';
      this.cursorPosition = 0;
      this.historyIndex = -1;
      return;
    }
    
    if (data === '\u001b[A') { // Up arrow - history navigation
      if (this.historyIndex < this.commandHistory.length - 1) {
        this.historyIndex++;
        this.replaceCurrentCommand(this.commandHistory[this.historyIndex]);
      }
      return;
    }
    
    if (data === '\u001b[B') { // Down arrow - history navigation
      if (this.historyIndex > 0) {
        this.historyIndex--;
        this.replaceCurrentCommand(this.commandHistory[this.historyIndex]);
      } else if (this.historyIndex === 0) {
        this.historyIndex = -1;
        this.replaceCurrentCommand('');
      }
      return;
    }
    
    if (data === '\u001b[C') { // Right arrow - move cursor right
      if (this.cursorPosition < this.currentCommand.length) {
        this.cursorPosition++;
        this.emitData(data);
      }
      return;
    }
    
    if (data === '\u001b[D') { // Left arrow - move cursor left
      if (this.cursorPosition > 0) {
        this.cursorPosition--;
        this.emitData(data);
      }
      return;
    }
    
    if (data === '\u001b[H') { // Home - move to start of line
      this.emitData('\r' + this.getPrompt());
      this.cursorPosition = 0;
      return;
    }
    
    if (data === '\u001b[F') { // End - move to end of line
      const moveRight = this.currentCommand.length - this.cursorPosition;
      if (moveRight > 0) {
        this.emitData('\u001b[' + moveRight + 'C');
        this.cursorPosition = this.currentCommand.length;
      }
      return;
    }
    
    if (data === '\u007f' || data === '\u0008') { // Backspace
      if (this.cursorPosition > 0) {
        const beforeCursor = this.currentCommand.substring(0, this.cursorPosition - 1);
        const afterCursor = this.currentCommand.substring(this.cursorPosition);
        this.currentCommand = beforeCursor + afterCursor;
        this.cursorPosition--;
        
        // Redraw the line
        this.emitData('\u001b[D\u001b[K' + afterCursor);
        
        // Move cursor back to position
        if (afterCursor.length > 0) {
          this.emitData('\u001b[' + afterCursor.length + 'D');
        }
      }
      return;
    }
    
    if (data === '\u001b[3~') { // Delete
      if (this.cursorPosition < this.currentCommand.length) {
        const beforeCursor = this.currentCommand.substring(0, this.cursorPosition);
        const afterCursor = this.currentCommand.substring(this.cursorPosition + 1);
        this.currentCommand = beforeCursor + afterCursor;
        
        // Redraw the line
        this.emitData('\u001b[K' + afterCursor);
        
        // Move cursor back to position
        if (afterCursor.length > 0) {
          this.emitData('\u001b[' + afterCursor.length + 'D');
        }
      }
      return;
    }
    
    // Regular character input
    if (data.length === 1 && data.charCodeAt(0) >= 32) {
      // Insert character at cursor position
      const beforeCursor = this.currentCommand.substring(0, this.cursorPosition);
      const afterCursor = this.currentCommand.substring(this.cursorPosition);
      this.currentCommand = beforeCursor + data + afterCursor;
      this.cursorPosition++;
      
      // Echo the character and redraw anything after cursor
      this.emitData(data + afterCursor);
      
      // Move cursor back to position
      if (afterCursor.length > 0) {
        this.emitData('\u001b[' + afterCursor.length + 'D');
      }
    }
  }
  
  replaceCurrentCommand(newCommand) {
    // Clear current line and replace with new command
    this.emitData('\r\u001b[K' + this.getPrompt() + newCommand);
    this.currentCommand = newCommand;
    this.cursorPosition = newCommand.length;
  }
  
  executeCommand(command) {
    const cmd = command.trim();
    
    // Handle built-in commands
    if (cmd === 'clear') {
      this.emitData('\u001b[2J\u001b[H');
      this.emitData(this.getPrompt());
      return;
    }
    
    if (cmd === 'pwd') {
      this.emitData(this.options.cwd + '\r\n' + this.getPrompt());
      return;
    }
    
    if (cmd === 'ls') {
      this.emitData('docker-compose.yml  stack1  stack2  stack3\r\n' + this.getPrompt());
      return;
    }
    
    if (cmd.startsWith('cd ')) {
      this.emitData(this.getPrompt());
      return;
    }
    
    // For docker commands, show a simulated response
    if (cmd.startsWith('docker')) {
      this.emitData('Command would be executed: ' + cmd + '\r\n');
      this.emitData('This is a simulated response in the mock terminal.\r\n');
      this.emitData(this.getPrompt());
      return;
    }
    
    // Default response for other commands
    this.emitData('Command not implemented in mock terminal: ' + cmd + '\r\n');
    this.emitData(this.getPrompt());
  }
  
  getPrompt() {
    const username = os.userInfo().username || 'user';
    const hostname = os.hostname() || 'rackge';
    const cwd = this.options.cwd || process.cwd();
    const shortCwd = cwd.split(path.sep).pop();
    return username + '@' + hostname + ':~/' + shortCwd + '$ ';
  }
  
  emitData(data) {
    this.emit('data', data);
  }
  
  resize(cols, rows) {
    this.cols = cols;
    this.rows = rows;
  }
  
  kill() {
    this.running = false;
    this.emit('exit', 0);
  }
  
  on(event, listener) {
    super.on(event, listener);
    return this;
  }
  
  onData(listener) {
    this.on('data', listener);
    return this;
  }
  
  onExit(listener) {
    this.on('exit', listener);
    return this;
  }
  
  removeAllListeners(event) {
    super.removeAllListeners(event);
    return this;
  }
}

function spawn(file, args, options) {
  console.log("node-pty mock: spawn called for", file, args);
  return new PtyProcess(file, args, options);
}

module.exports = {
  spawn: spawn,
  Platform: { Windows: 0, Unix: 1 },
  Process: "bash"
};
EOF
  
  # Create the node_modules/node-pty directory if it doesn't exist
  if [ ! -d "/app/node_modules/node-pty" ]; then
    echo "Creating node-pty mock module"
    mkdir -p /app/node_modules/node-pty
    cp /app/node-pty-mock/index.js /app/node_modules/node-pty/
    
    # Create a package.json for the mock module
    cat > /app/node_modules/node-pty/package.json << 'EOF'
{
  "name": "node-pty",
  "version": "0.10.1",
  "main": "index.js"
}
EOF
  fi
  
  echo "Node-pty mock setup complete"
else
  echo "NODE_PTY_MOCK not enabled, skipping mock setup"
fi

# Fix SQLite3 paths
echo "Fixing SQLite3 paths..."

# Create required directories
SQLITE3_MODULE_PATH="/app/node_modules/.pnpm/@louislam+sqlite3@15.1.6_encoding@0.1.13/node_modules/@louislam/sqlite3/lib/binding"
mkdir -p "$SQLITE3_MODULE_PATH/napi-v6-linux-arm64"

# Create a mock SQLite3 native module
cat > "$SQLITE3_MODULE_PATH/napi-v6-linux-arm64/node_sqlite3.node.js" << 'EOF'
console.log("Using SQLite3 mock implementation");
module.exports = {};
EOF

# Create a symbolic link to the JS file as the .node file
ln -sf "$SQLITE3_MODULE_PATH/napi-v6-linux-arm64/node_sqlite3.node.js" "$SQLITE3_MODULE_PATH/napi-v6-linux-arm64/node_sqlite3.node"

# Fix the entire SQLite3 module to use our mock
SQLITE3_PATH="/app/node_modules/.pnpm/@louislam+sqlite3@15.1.6_encoding@0.1.13/node_modules/@louislam/sqlite3/lib"

# Create a backup of the original files
if [ -f "$SQLITE3_PATH/sqlite3.js" ]; then
  cp "$SQLITE3_PATH/sqlite3.js" "${SQLITE3_PATH}/sqlite3.js.bak"
  cp "$SQLITE3_PATH/sqlite3-binding.js" "${SQLITE3_PATH}/sqlite3-binding.js.bak" 2>/dev/null || true
  
  # Replace the sqlite3.js with our mock version
  cat > "$SQLITE3_PATH/sqlite3.js" << 'EOF'
console.log("Using SQLite3 mock implementation");

const util = require('util');
const EventEmitter = require('events').EventEmitter;

function Database() {
  EventEmitter.call(this);
}

util.inherits(Database, EventEmitter);

Database.prototype.run = function() { return this; };
Database.prototype.exec = function() { return this; };
Database.prototype.prepare = function() { 
  return { 
    run: function() {}, 
    finalize: function() {},
    all: function(callback) { callback(null, []); }
  }; 
};
Database.prototype.close = function() {};
Database.prototype.all = function(sql, params, callback) {
  if (typeof params === 'function') {
    callback = params;
    params = [];
  }
  callback(null, []);
  return this;
};

module.exports = {
  Database: Database,
  verbose: function() { return module.exports; }
};
EOF
  
  # Replace the binding.js with our mock version
  cat > "$SQLITE3_PATH/sqlite3-binding.js" << 'EOF'
console.log("Using SQLite3 mock binding");
module.exports = require('./sqlite3.js');
EOF
fi

echo "SQLite3 paths fixed"
