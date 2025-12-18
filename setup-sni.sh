#!/bin/bash

# Скрипт установки и настройки Nginx + Certbot для Reality SNI
# Автор: GitHub Copilot
# Использование: sudo bash setup-reality-sni.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   print_error "Этот скрипт должен быть запущен с правами root (sudo)"
   exit 1
fi

# Проверка ОС
if [ ! -f /etc/os-release ]; then
    print_error "Не удалось определить операционную систему"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    print_warning "Скрипт оптимизирован для Ubuntu. Ваша ОС: $ID"
    read -p "Продолжить? (y/n): " continue_anyway
    if [[ "$continue_anyway" != "y" ]]; then
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  Reality SNI Setup Script"
echo "=========================================="
echo ""

# Запрос доменного имени
read -p "Введите доменное имя (например, example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    print_error "Доменное имя не может быть пустым"
    exit 1
fi

# Запрос email для Certbot
read -p "Введите email для Certbot (для уведомлений): " EMAIL
if [[ -z "$EMAIL" ]]; then
    print_error "Email не может быть пустым"
    exit 1
fi

# Подтверждение
echo ""
print_message "Будет выполнена настройка для домена: $DOMAIN"
print_message "Email для сертификата: $EMAIL"
read -p "Продолжить? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    print_message "Установка отменена"
    exit 0
fi

# Установка Nginx и Certbot
print_message "Обновление списка пакетов..."
apt update

print_message "Установка Nginx и Certbot..."
apt install -y nginx certbot python3-certbot-nginx

# Удаление default конфигурации
print_message "Удаление стандартной конфигурации..."
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Создание директории для сайта
print_message "Создание директории для сайта..."
mkdir -p /var/www/html/site

# Генерация случайной HTML заглушки
print_message "Генерация HTML заглушки..."

# Массивы для случайного контента
TITLES=(
    "Welcome"
    "Under Construction"
    "Coming Soon"
    "Site Maintenance"
    "New Website"
    "Hello World"
    "Website"
    "Portal"
)

MESSAGES=(
    "This website is currently under construction."
    "We're working on something awesome!"
    "Our new site is coming soon."
    "Please check back later."
    "Stay tuned for updates."
    "Great things are coming."
    "We'll be back soon."
    "Something exciting is in the works."
)

COLORS=(
    "#2c3e50"
    "#34495e"
    "#16a085"
    "#27ae60"
    "#2980b9"
    "#8e44ad"
    "#2c2c2c"
    "#1a1a1a"
)

BG_COLORS=(
    "#ecf0f1"
    "#f5f5f5"
    "#ffffff"
    "#e8f4f8"
    "#f0f0f0"
)

# Выбор случайных элементов
RAND_TITLE=${TITLES[$RANDOM % ${#TITLES[@]}]}
RAND_MESSAGE=${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}
RAND_COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
RAND_BG=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

# Создание HTML файла
cat > /var/www/html/site/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$RAND_TITLE</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, $RAND_BG 0%, ${RAND_COLOR}22 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            text-align: center;
            background: white;
            padding: 60px 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
            max-width: 600px;
            animation: fadeIn 1s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        h1 {
            color: $RAND_COLOR;
            font-size: 3em;
            margin-bottom: 20px;
            font-weight: 700;
        }
        p {
            color: #666;
            font-size: 1.2em;
            line-height: 1.6;
            margin-bottom: 30px;
        }
        .domain {
            color: $RAND_COLOR;
            font-weight: 600;
            font-size: 1.1em;
            margin-top: 30px;
            padding: 15px;
            background: ${RAND_COLOR}11;
            border-radius: 10px;
        }
        .spinner {
            width: 50px;
            height: 50px;
            border: 5px solid #f3f3f3;
            border-top: 5px solid $RAND_COLOR;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 30px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$RAND_TITLE</h1>
        <div class="spinner"></div>
        <p>$RAND_MESSAGE</p>
        <div class="domain">$DOMAIN</div>
    </div>
</body>
</html>
EOF

print_message "HTML заглушка создана"

# Создание начальной конфигурации Nginx для получения сертификата
print_message "Создание конфигурации Nginx..."
cat > /etc/nginx/sites-available/sni.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;

    if (\$host = $DOMAIN) {
        return 301 https://\$host\$request_uri;
    } 

    return 404;
}
EOF

# Включение сайта
print_message "Активация конфигурации..."
ln -sf /etc/nginx/sites-available/sni.conf /etc/nginx/sites-enabled/

# Проверка конфигурации Nginx
print_message "Проверка конфигурации Nginx..."
nginx -t

# Перезагрузка Nginx
print_message "Перезагрузка Nginx..."
systemctl restart nginx

# Получение SSL сертификата
print_message "Получение SSL сертификата через Certbot..."
print_warning "Убедитесь, что домен $DOMAIN указывает на IP этого сервера!"
sleep 3

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# Обновление конфигурации для Reality
print_message "Обновление конфигурации для Reality (порт 8443 с proxy_protocol)..."
cat > /etc/nginx/sites-available/sni.conf << EOF
server {
    listen 127.0.0.1:8443 ssl http2 proxy_protocol;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # Настройки Proxy Protocol
    real_ip_header proxy_protocol;
    set_real_ip_from 127.0.0.1;
    set_real_ip_from ::1;

    root /var/www/html/site;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Финальная проверка конфигурации
print_message "Финальная проверка конфигурации..."
nginx -t

# Перезагрузка Nginx
print_message "Перезагрузка Nginx..."
systemctl restart nginx

# Проверка статуса
systemctl status nginx --no-pager

echo ""
echo "=========================================="
echo "  ✓ Установка завершена успешно!"
echo "=========================================="
echo ""
print_message "Конфигурация Reality:"
echo "  DEST (Target): 127.0.0.1:8443"
echo "  SNI (Server Name): $DOMAIN"
echo "  xver: 1"
echo ""
print_message "Файлы:"
echo "  Конфигурация: /etc/nginx/sites-available/sni.conf"
echo "  HTML заглушка: /var/www/html/site/index.html"
echo "  SSL сертификат: /etc/letsencrypt/live/$DOMAIN/"
echo ""
print_message "Сайт доступен локально по адресу: 127.0.0.1:8443"
print_message "SSL сертификат будет автоматически обновляться через Certbot"
echo ""
print_warning "Не забудьте оставить порт 80 открытым для автообновления сертификата!"
echo ""
