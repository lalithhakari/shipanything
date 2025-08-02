# Multi-stage Dockerfile for auth-app microservice
# Stage 1: Build stage
FROM php:8.2-fpm as builder

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    zip \
    unzip \
    nginx \
    && docker-php-ext-install pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy application code
COPY . .

# Generate application key and optimize
RUN php artisan key:generate --force \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && composer dump-autoload --optimize

# Stage 2: Production stage
FROM php:8.2-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    nginx \
    supervisor \
    git \
    curl \
    unzip \
    && docker-php-ext-install pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer directly in production stage
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer && \
    ln -sf /usr/local/bin/composer /usr/bin/composer

# Create application user
RUN groupadd -g 1000 www \
    && useradd -u 1000 -ms /bin/bash -g www www

# Set working directory
WORKDIR /var/www/html

# Copy application from builder stage
COPY --from=builder --chown=www:www /var/www/html /var/www/html

# Configure Nginx
COPY --chown=www:www <<EOF /etc/nginx/sites-available/default
server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Configure Supervisor
COPY --chown=www:www <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:php-fpm]
command=php-fpm
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/php-fpm.err.log
stdout_logfile=/var/log/supervisor/php-fpm.out.log

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/nginx.err.log
stdout_logfile=/var/log/supervisor/nginx.out.log

[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/supervisor/worker.log
EOF

# Set proper permissions
RUN chown -R www:www /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && chown www:www /usr/local/bin/composer \
    && chown www:www /usr/bin/composer

# Create log directories and set permissions
RUN mkdir -p /var/log/supervisor \
    && touch /var/log/supervisor/supervisord.log \
    && chown -R www:www /var/log/supervisor

# Create startup script to fix permissions and start supervisord
RUN echo '#!/bin/bash' > /startup.sh && \
    echo 'set -e' >> /startup.sh && \
    echo '' >> /startup.sh && \
    echo '# Fix permissions for Laravel storage and cache directories' >> /startup.sh && \
    echo 'echo "Fixing Laravel permissions..."' >> /startup.sh && \
    echo 'chown -R www:www /var/www/html/storage' >> /startup.sh && \
    echo 'chown -R www:www /var/www/html/bootstrap/cache' >> /startup.sh && \
    echo 'chmod -R 775 /var/www/html/storage' >> /startup.sh && \
    echo 'chmod -R 775 /var/www/html/bootstrap/cache' >> /startup.sh && \
    echo '' >> /startup.sh && \
    echo '# Ensure log directories have correct permissions' >> /startup.sh && \
    echo 'chown -R www:www /var/log/supervisor' >> /startup.sh && \
    echo '' >> /startup.sh && \
    echo '# Start supervisord' >> /startup.sh && \
    echo 'echo "Starting supervisord..."' >> /startup.sh && \
    echo 'exec supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /startup.sh && \
    chmod +x /startup.sh

# Expose port 80
EXPOSE 80

# Start with startup script that fixes permissions and runs supervisord as root
CMD ["/startup.sh"]
