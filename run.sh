#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Go to backend directory
echo "🔧 Setting up backend..."
cd backend
npm install
npm start &  # run in background

# Go back to the root and go to frontend
cd ../frontend
echo "🎨 Setting up frontend..."
npm install
npm run dev
