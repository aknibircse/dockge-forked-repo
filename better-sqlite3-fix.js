// better-sqlite3-fix.js
// This script sets environment variables to use pre-built binaries for better-sqlite3
// and other native modules instead of trying to compile them

process.env.npm_config_sqlite_libvfs = "false";
process.env.npm_config_sqlite = "false";
process.env.npm_config_sqlite_build_binary = "false";
process.env.npm_config_sqlite_prebuilt = "true";

// For other native modules
process.env.SKIP_NATIVE_BUILD = "true";

// Load the actual application
import("./backend/index.js");
