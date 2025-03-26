// This is a simple wrapper script to run the compiled backend code
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Create a require function
const require = createRequire(import.meta.url);

// Get the directory name of the current module
const __dirname = dirname(fileURLToPath(import.meta.url));

// Import and run the compiled index.js file
const distPath = join(__dirname, 'dist/backend/index.js');

// Log startup message
console.log(`Starting Rackge from ${distPath}`);

// Dynamic import of the compiled index.js
import(distPath).catch(err => {
  console.error('Error starting Rackge:', err);
  process.exit(1);
});
