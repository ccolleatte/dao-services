/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    config.externals.push('pino-pretty', 'lokijs', 'encoding');
    return config;
  },
  typescript: {
    // Type checking done separately with tsc --noEmit
    ignoreBuildErrors: false,
  },
  eslint: {
    dirs: ['pages', 'components', 'services', 'types'],
  },
};

module.exports = nextConfig;
