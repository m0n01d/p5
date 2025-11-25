import { defineConfig } from 'vite'

export default defineConfig({
  base: '/p5/',
  build: {
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          // Keep sketch files as separate chunks for dynamic import
          if (id.includes('Sketch.res.mjs')) {
            return id.split('/').pop().replace('.res.mjs', '');
          }
        }
      }
    }
  }
})
