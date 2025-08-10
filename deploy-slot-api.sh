#!/bin/bash

APP_NAME="slot-api"
APP_DIR="/var/www/project/games"
DOMAIN="api.zivilia.xyz"
PORT=5001

echo "🚀 Deploying $APP_NAME..."

# Masuk ke folder project
cd $APP_DIR || exit

# 1. Install dependencies
echo "📦 Installing dependencies..."
npm install

# 2. Build project
echo "🔨 Building project..."
npx tsc

# 3. Restart via PM2
echo "♻️ Restarting PM2 process..."
pm2 stop $APP_NAME || true
pm2 delete $APP_NAME || true
pm2 start dist/server.js --name $APP_NAME
pm2 save

# 4. Setup Apache reverse proxy
echo "⚙️ Setting up Apache reverse proxy for $DOMAIN..."
CONF_FILE="/etc/apache2/sites-available/${DOMAIN}-le-ssl.conf"

sudo bash -c "cat > $CONF_FILE" <<EOL
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName $DOMAIN

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:$PORT/
    ProxyPassReverse / http://127.0.0.1:$PORT/

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOL

# 5. Aktifkan module Apache
echo "🔌 Enabling Apache modules..."
sudo a2enmod proxy proxy_http ssl
sudo systemctl restart apache2

echo "✅ Deployment complete! API ready at https://$DOMAIN"

