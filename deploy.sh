#!/bin/bash
APP_NAME="slot-api"
APP_DIR="/var/www/project/games"
LOG_FILE="/var/log/deploy-${APP_NAME}.log"

echo "🚀 Starting deployment for ${APP_NAME} at $(date)" | tee -a $LOG_FILE

cd $APP_DIR || { echo "❌ Directory not found!"; exit 1; }

# Step 1: Pull latest changes
echo "📥 Pulling latest changes..." | tee -a $LOG_FILE
git reset --hard
git pull origin main >> $LOG_FILE 2>&1

# Step 2: Install dependencies
echo "📦 Installing dependencies..." | tee -a $LOG_FILE
npm install >> $LOG_FILE 2>&1

# Step 3: Build TypeScript
echo "🔨 Building TypeScript..." | tee -a $LOG_FILE
npx tsc >> $LOG_FILE 2>&1

# Step 4: Restart PM2
echo "♻️ Restarting PM2 service..." | tee -a $LOG_FILE
pm2 restart $APP_NAME >> $LOG_FILE 2>&1
pm2 save >> $LOG_FILE 2>&1

echo "✅ Deployment finished at $(date)" | tee -a $LOG_FILE

