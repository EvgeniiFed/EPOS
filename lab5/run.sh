#!/bin/bash

CONTAINER_NAME="lab5-nginx"
IMAGE_NAME="lab5-nginx-image"
HOST_PORT_HTTP=8080
HOST_PORT_HTTPS=54321

echo "🚀 Запуск процесса деплоя..."

# 1. Генерируем сертификат, если его еще нет (чтобы Nginx не упал при старте)
if [ ! -f "certs/server.crt" ]; then
    echo "🔒 Сертификат не найден. Генерируем..."
    ./generate_cert.sh
fi

# 2. Останавливаем и удаляем старый контейнер, если он есть
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# 3. Собираем Docker образ
echo "📦 Сборка Docker образа..."
docker build -t $IMAGE_NAME .

# 4. Запускаем контейнер
echo "🐳 Запуск контейнера..."
docker run -d \
    --name $CONTAINER_NAME \
    -p ${HOST_PORT_HTTP}:80 \
    -p ${HOST_PORT_HTTPS}:443 \
    -v $(pwd)/certs:/etc/nginx/certs:ro \
    $IMAGE_NAME

echo "✅ Контейнер успешно запущен!"
echo "🌐 HTTP:  http://localhost:${HOST_PORT_HTTP}"
echo "🔒 HTTPS: https://localhost:${HOST_PORT_HTTPS}"