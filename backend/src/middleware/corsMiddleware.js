/**
 * CORS middleware configuration
 * Allows requests from all origins for development
 */
const cors = require('cors');

const corsOptions = {
  origin: '*', // Allow all origins
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  credentials: false,
  optionsSuccessStatus: 200,
  allowedHeaders: ['Content-Type', 'Authorization'],
};

module.exports = cors(corsOptions);
