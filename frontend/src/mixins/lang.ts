import { currentLocale } from "../i18n";
import { setPageLocale } from "../util-frontend";
import { defineComponent } from "vue";
// Use relative path with eager loading for better compatibility
const langModules = import.meta.glob("../lang/*.json", { eager: true });

export default defineComponent({
    data() {
        return {
            language: currentLocale(),
        };
    },

    watch: {
        async language(lang) {
            await this.changeLang(lang);
        },
    },

    async created() {
        if (this.language !== "en") {
            await this.changeLang(this.language);
        }
    },

    methods: {
        /**
         * Change the application language
         * @param {string} lang Language code to switch to
         * @returns {Promise<void>}
         */
        async changeLang(lang : string) {
            // With eager loading, modules are already loaded and available directly
            const modulePath = `../lang/${lang}.json`;
            if (modulePath in langModules) {
                const message = (langModules[modulePath] as any).default;
                this.$i18n.setLocaleMessage(lang, message);
                this.$i18n.locale = lang;
                localStorage.locale = lang;
                setPageLocale();
            } else {
                console.error(`Language file not found: ${modulePath}`);
            }
        }
    }
});
