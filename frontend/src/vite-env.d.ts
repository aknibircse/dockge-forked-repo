/* eslint-disable */
/// <reference types="vite/client" />

declare module "*.vue" {
    import type { DefineComponent } from "vue";
    const component: DefineComponent<{}, {}, any>;
    export default component;
}

// Vite's types are already included via /// <reference types="vite/client" />
// No need to redefine them here

// Declare global constants defined in vite.config.ts
declare const FRONTEND_VERSION: string;
declare const DEVCONTAINER: string;
declare const CODESPACE_NAME: string;
declare const GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN: string;
