import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
    plugins: [react()],
    base: '/admin/',
    build: {
        outDir: '../admin-dist',
        emptyOutDir: true,
    },
    server: {
        port: 3001,
        proxy: {
            '/api': {
                target: 'http://localhost:8787',
                changeOrigin: true,
            }
        }
    }
});
