import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    cpus: 1,
    webpackMemoryOptimizations: true,
  },
  webpack(config, { isServer, webpack }) {
    if (!isServer) {
      // Webpack handles node: URLs before @libp2p/http-utils's browser map.
      // Apply that package's own polyfill just for its imports; remove this
      // when it ships a browser-specific module that Webpack resolves directly.
      config.plugins.push(
        new webpack.NormalModuleReplacementPlugin(
          /^node:stream$/,
          (request: { context: string; request: string }) => {
            if (/[/\\]@libp2p[/\\]http-utils[/\\]/.test(request.context)) {
              request.request = "readable-stream";
            }
          },
        ),
      );
    }
    return config;
  },
};

export default nextConfig;
