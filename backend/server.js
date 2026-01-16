require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const { connectDB } = require('./src/config/mongoose');
const serverConfig = require('./src/config/server');
const corsMiddleware = require('./src/middleware/corsMiddleware');
const errorHandler = require('./src/middleware/errorHandler');
const logger = require('./src/utils/logger');

// Import routes
const menuRoutes = require('./src/api/menuRoutes');
const billingRoutes = require('./src/api/billingRoutes');
const menuRoutesV1 = require('./src/api/menuRoutesV1');
const billingRoutesV1 = require('./src/api/billingRoutesV1');

const app = express();

// Middleware - Body parser MUST come first
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(corsMiddleware);

// Request logging middleware (after body-parser so req.body is available)
app.use((req, res, next) => {
  const startTime = Date.now();
  logger.info(`[${req.method}] ${req.path} - Client: ${req.ip}`);

  // Log request body for POST/PUT requests
  if (req.method === 'POST' || req.method === 'PUT') {
    logger.info(`Request Body: ${JSON.stringify(req.body)}`);
  }

  // Capture response
  const originalSend = res.send;
  res.send = function (data) {
    const duration = Date.now() - startTime;
    logger.info(`[${req.method}] ${req.path} - Status: ${res.statusCode} - Duration: ${duration}ms`);
    return originalSend.call(this, data);
  };

  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
  });
});

// API Routes - Original (In-Memory)
app.use('/api/menu', menuRoutes);
app.use('/api/billing', billingRoutes);

// API Routes - V1 (MongoDB)
app.use('/api/v1/menu', menuRoutesV1);
app.use('/api/v1/billing', billingRoutesV1);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Start server with database connection
const startServer = async () => {
  try {
    // Connect to MongoDB if not in memory-only mode
    if (process.env.NODE_ENV !== 'memory-only') {
      await connectDB();
    }

    const PORT = serverConfig.port;
    const HOST = serverConfig.host;

    app.listen(PORT, HOST, () => {
      logger.info(`Undhiyu Backend Server running on http://${HOST}:${PORT}`);
      logger.info(`Environment: ${serverConfig.nodeEnv}`);
      logger.info(`Database: ${process.env.NODE_ENV === 'memory-only' ? 'In-Memory' : 'MongoDB'}`);
      logger.info(`Health check: http://${HOST}:${PORT}/health`);
      logger.info('');
      logger.info('Available API versions:');
      logger.info('  v0 (In-Memory): /api/menu, /api/billing');
      logger.info('  v1 (MongoDB): /api/v1/menu, /api/v1/billing');
    });
  } catch (error) {
    logger.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;
