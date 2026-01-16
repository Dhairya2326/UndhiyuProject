/**
 * Server configuration
 */

const config = {
  development: {
    port: process.env.PORT || 5000,
    host: 'localhost',
    nodeEnv: 'development',
  },
  production: {
    port: process.env.PORT || 5000,
    host: '0.0.0.0',
    nodeEnv: 'production',
  },
  test: {
    port: 5001,
    host: 'localhost',
    nodeEnv: 'test',
  },
};

const env = process.env.NODE_ENV || 'development';
module.exports = config[env];
