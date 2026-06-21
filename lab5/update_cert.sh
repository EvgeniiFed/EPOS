#!/bin/bash

CONTAINER_NAME="lab5-nginx"

echo "🔄 Обновление SSL сертификата..."

# 1. Перегенерируем сертификат
./generate_cert.sh

# 2. Отправляем сигнал reload внутрь работающего контейнера
echo "🔁 Перечитывание конфигурации Nginx внутри контейнера..."
docker exec $CONTAINER_NAME nginx -s reload

echo "✅ Сертификат обновлен, Nginx перечитал конфигурацию без простоя!"