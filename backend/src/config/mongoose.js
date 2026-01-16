const mongoose = require('mongoose');
const logger = require('../utils/logger');

// MongoDB Connection
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/undhiyu';
    
    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    logger.info(`MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    logger.error('MongoDB Connection Error:', error.message);
    logger.error('Error Code:', error.code);
    logger.error('Full Error:', error);
    
    // Provide helpful error message
    if (error.message.includes('ECONNREFUSED')) {
      logger.error('MongoDB is not running. Start MongoDB with:');
      logger.error('  Windows: mongod');
      logger.error('  Mac/Linux: mongod');
      logger.error('OR use MongoDB Atlas (cloud):');
      logger.error('  Set MONGODB_URI=mongodb+srv://... in .env');
    }
    
    if (error.message.includes('bad auth') || error.message.includes('authentication failed')) {
      logger.error('Authentication failed! Check:');
      logger.error('  1. Username and password in MongoDB Atlas');
      logger.error('  2. IP Whitelist (Network Access) in MongoDB Atlas');
      logger.error('  3. Database name in connection string');
    }
    
    process.exit(1);
  }
};

// Disconnect from MongoDB
const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    logger.info('MongoDB Disconnected');
  } catch (error) {
    logger.error('Error disconnecting MongoDB:', error.message);
    process.exit(1);
  }
};

module.exports = { connectDB, disconnectDB };
