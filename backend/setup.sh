#!/bin/bash

# Undhiyu Catering App - Backend Setup Script
# This script sets up the backend environment

echo "================================"
echo "Undhiyu Backend Setup"
echo "================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js version: $(node --version)"
echo "✓ npm version: $(npm --version)"
echo ""

# Navigate to backend directory
cd backend || exit 1

echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "✓ Dependencies installed successfully!"
echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "To start the backend server, run:"
echo "  npm run dev (for development with auto-reload)"
echo "  npm start (for production)"
echo ""
echo "The server will be available at:"
echo "  http://localhost:5000"
echo ""
echo "API Documentation:"
echo "  Menu API: http://localhost:5000/api/menu"
echo "  Billing API: http://localhost:5000/api/billing"
echo "  Health Check: http://localhost:5000/health"
echo ""
