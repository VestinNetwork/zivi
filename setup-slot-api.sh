#!/bin/bash
set -e

PROJECT_DIR="/var/www/project/games"
DOMAIN="api.zivilia.xyz"
NODE_VERSION="20"

echo "=== 1. Update & install basic packages ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release ca-certificates software-properties-common apt-transport-https build-essential

echo "=== 2. Install Node.js & PM2 ==="
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2

echo "=== 3. Install PostgreSQL client ==="
sudo apt install -y postgresql-client

echo "=== 4. Install pgAdmin4 Web ==="
curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/pgadmin-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/pgadmin-keyring.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/jammy pgadmin4 main" | sudo tee /etc/apt/sources.list.d/pgadmin4.list
sudo apt update
sudo apt install -y pgadmin4-web
sudo /usr/pgadmin4/bin/setup-web.sh

echo "=== 5. Setup project structure ==="
sudo mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
npm init -y
npm install express pg cors dotenv
npm install --save-dev typescript @types/node @types/express ts-node nodemon
npx tsc --init

echo "=== 6. Create TypeScript API server ==="
mkdir -p src
cat <<'EOF' > src/server.ts
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Slot API running 🚀' });
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
EOF

echo "=== 7. Build project ==="
npx tsc

echo "=== 8. Setup Apache reverse proxy ==="
APACHE_CONF="/etc/apache2/sites-available/${DOMAIN}.conf"
sudo bash -c "cat > $APACHE_CONF" <<EOL
<VirtualHost *:80>
    ServerName $DOMAIN
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
EOL

sudo a2enmod proxy proxy_http
sudo a2ensite ${DOMAIN}.conf
sudo systemctl restart apache2

echo "=== 9. Setup SSL with Certbot ==="
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

echo "=== 10. Start API with PM2 ==="
pm2 start dist/server.js --name slot-api
pm2 save
pm2 startup

echo "=== Setup complete! ==="
echo "API ready at: https://$DOMAIN"

