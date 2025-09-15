#!/bin/bash
# سكريبت لإعداد Pterodactyl Panel + Theme داخل docker-compose.yml

mkdir -p pterodactyl/panel
cd pterodactyl/panel || exit

# إنشاء docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  database:
    image: mariadb:10.5
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: change_me_root
      MYSQL_DATABASE: panel
      MYSQL_USER: pterodactyl
      MYSQL_PASSWORD: change_me_pass
    volumes:
      - ./data/mysql:/var/lib/mysql

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:v1.11.11
    restart: always
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - database
      - cache
    volumes:
      - ./data/panel:/app
      - ./theme-install.sh:/theme-install.sh
    entrypoint: ["/bin/bash", "-c", "/theme-install.sh && php-fpm"]
    environment:
      APP_ENV: production
      APP_URL: "http://localhost:8080"
      APP_TIMEZONE: "UTC"
      DB_HOST: database
      DB_PORT: 3306
      DB_DATABASE: panel
      DB_USERNAME: pterodactyl
      DB_PASSWORD: change_me_pass
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
      QUEUE_DRIVER: redis
      REDIS_HOST: cache
      MAIL_DRIVER: smtp
      MAIL_FROM: "noreply@example.com"
      MAIL_HOST: mail
      MAIL_PORT: 1025

networks:
  default:
    driver: bridge
EOF

# سكريبت لتثبيت الثيم داخل الكونتينر
cat <<'EOF' > theme-install.sh
#!/bin/bash
set -e

echo "🎨 Installing NookTheme for Pterodactyl Panel..."

cd /app || exit

php artisan down || true

# تحميل الثيم من GitHub
curl -L https://github.com/Nookure/NookTheme/releases/latest/download/panel.tar.gz | tar -xzv

chmod -R 755 storage/* bootstrap/cache
composer install --no-dev --optimize-autoloader
php artisan view:clear
php artisan config:clear
php artisan migrate --seed --force
chown -R www-data:www-data /app/*
php artisan queue:restart
php artisan up

echo "✅ Theme installed successfully!"
EOF

chmod +x theme-install.sh

echo "✅ docker-compose.yml + theme-install.sh created. Run:"
echo "   docker-compose up -d"
