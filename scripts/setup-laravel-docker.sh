#!/bin/bash

# Script to monitor Laravel app creation and set up Docker configurations
# This script will be run after each Laravel app is created

set -e

APP_NAME=$1
if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <app-name>"
    exit 1
fi

APP_DIR="/Users/lalith/Documents/Projects/shipanything/microservices/${APP_NAME}"

echo "Setting up Docker configuration for ${APP_NAME}..."

# Create docker directory
mkdir -p "${APP_DIR}/docker"

# Create Nginx configuration
cat > "${APP_DIR}/docker/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    upstream php-fpm {
        server 127.0.0.1:9000;
    }
    
    server {
        listen 80;
        server_name _;
        root /var/www/html/public;
        index index.php index.html;
        
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
        
        location ~ \.php$ {
            fastcgi_pass php-fpm;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
        
        location ~ /\.ht {
            deny all;
        }
    }
}
EOF

# Create PHP-FPM configuration
cat > "${APP_DIR}/docker/php-fpm.conf" << 'EOF'
[www]
user = www-data
group = www-data
listen = 127.0.0.1:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF

# Create startup script
cat > "${APP_DIR}/docker/start.sh" << 'EOF'
#!/bin/sh

# Start PHP-FPM in background
php-fpm -D

# Start Nginx in foreground
nginx -g "daemon off;"
EOF

chmod +x "${APP_DIR}/docker/start.sh"

# Update Laravel .env for containerized environment
if [ -f "${APP_DIR}/.env" ]; then
    # Update database configuration based on service
    case $APP_NAME in
        "auth-app")
            sed -i '' 's/DB_HOST=.*/DB_HOST=auth-postgres/' "${APP_DIR}/.env"
            sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=auth_db/' "${APP_DIR}/.env"
            sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=auth_user/' "${APP_DIR}/.env"
            sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=auth_password/' "${APP_DIR}/.env"
            sed -i '' 's/REDIS_HOST=.*/REDIS_HOST=auth-redis/' "${APP_DIR}/.env"
            ;;
        "location-app")
            sed -i '' 's/DB_HOST=.*/DB_HOST=location-postgres/' "${APP_DIR}/.env"
            sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=location_db/' "${APP_DIR}/.env"
            sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=location_user/' "${APP_DIR}/.env"
            sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=location_password/' "${APP_DIR}/.env"
            sed -i '' 's/REDIS_HOST=.*/REDIS_HOST=location-redis/' "${APP_DIR}/.env"
            ;;
        "payments-app")
            sed -i '' 's/DB_HOST=.*/DB_HOST=payments-postgres/' "${APP_DIR}/.env"
            sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=payments_db/' "${APP_DIR}/.env"
            sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=payments_user/' "${APP_DIR}/.env"
            sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=payments_password/' "${APP_DIR}/.env"
            sed -i '' 's/REDIS_HOST=.*/REDIS_HOST=payments-redis/' "${APP_DIR}/.env"
            ;;
        "booking-app")
            sed -i '' 's/DB_HOST=.*/DB_HOST=booking-postgres/' "${APP_DIR}/.env"
            sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=booking_db/' "${APP_DIR}/.env"
            sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=booking_user/' "${APP_DIR}/.env"
            sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=booking_password/' "${APP_DIR}/.env"
            sed -i '' 's/REDIS_HOST=.*/REDIS_HOST=booking-redis/' "${APP_DIR}/.env"
            ;;
        "fraud-detector-app")
            sed -i '' 's/DB_HOST=.*/DB_HOST=fraud-postgres/' "${APP_DIR}/.env"
            sed -i '' 's/DB_DATABASE=.*/DB_DATABASE=fraud_db/' "${APP_DIR}/.env"
            sed -i '' 's/DB_USERNAME=.*/DB_USERNAME=fraud_user/' "${APP_DIR}/.env"
            sed -i '' 's/DB_PASSWORD=.*/DB_PASSWORD=fraud_password/' "${APP_DIR}/.env"
            sed -i '' 's/REDIS_HOST=.*/REDIS_HOST=fraud-redis/' "${APP_DIR}/.env"
            ;;
    esac
    
    # Add Kafka configuration
    echo "" >> "${APP_DIR}/.env"
    echo "# Kafka Configuration" >> "${APP_DIR}/.env"
    echo "KAFKA_BROKERS=kafka:29092" >> "${APP_DIR}/.env"
fi

echo "Docker configuration for ${APP_NAME} completed!"
