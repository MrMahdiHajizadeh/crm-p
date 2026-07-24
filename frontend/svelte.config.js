import adapter from '@sveltejs/adapter-node';

const config = {
  vitePlugin: {
    prebundleSvelteLibraries: false
  },
  kit: {
    adapter: adapter(),
    csrf: {
      checkOrigin: false
    },
    version: {
      pollInterval: 60000
    },
    experimental: {
      tracing: {
        server: true
      },
      instrumentation: {
        server: true
      }
    }
  }
};

export default config;