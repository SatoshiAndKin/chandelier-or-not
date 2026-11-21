import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    cpus: 1,
    webpackMemoryOptimizations: true,
  },
  webpack(config, { isServer, webpack }) {
    if (!isServer) {
      // libp2p's browser HTTP service uses node:stream's Duplex. Let Next's
      // existing stream fallback supply it in browser bundles.
      config.plugins.push(new webpack.NormalModuleReplacementPlugin(/^node:stream$/, "stream"));
    }
    return config;
  },
};

export default nextConfig;
