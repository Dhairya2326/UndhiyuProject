/**
 * Database configuration
 * Currently using in-memory storage
 * Can be replaced with MongoDB, PostgreSQL, etc.
 */

const config = {
  development: {
    type: 'memory',
    logging: true,
  },
  production: {
    type: 'memory',
    logging: false,
  },
  test: {
    type: 'memory',
    logging: false,
  },
};

const env = process.env.NODE_ENV || 'development';
module.exports = config[env];
