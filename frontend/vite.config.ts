import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import Components from "unplugin-vue-components/vite";
import { BootstrapVueNextResolver } from "unplugin-vue-components/resolvers";
import viteCompression from "vite-plugin-compression";
import "vue";

const viteCompressionFilter = /\.(js|mjs|json|css|html|svg)$/i;

// https://vitejs.dev/config/
export default defineConfig({
    server: {
        port: 5555,
        proxy: {
            '/api': {
                target: 'http://localhost:5050',
                changeOrigin: true,
                ws: true,
            },
            '/socket.io': {
                target: 'http://localhost:5050',
                changeOrigin: true,
                ws: true,
            },
        },
    },
    define: {
        "FRONTEND_VERSION": JSON.stringify(process.env.VERSION || process.env.npm_package_version),
    },
    root: "./frontend",
    build: {
        outDir: "../frontend-dist",
    },
    plugins: [
        vue(),
        Components({
            resolvers: [ BootstrapVueNextResolver() ],
        }),
        viteCompression({
            algorithm: "gzip",
            filter: viteCompressionFilter,
        }),
        viteCompression({
            algorithm: "brotliCompress",
            filter: viteCompressionFilter,
        }),
    ],
});
