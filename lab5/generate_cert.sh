#!/bin/bash

# Создаем папку для сертификатов, если её нет
mkdir -p certs

# Генерируем самоподписанный SSL сертификат на 1 год
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout certs/server.key \
    -out certs/server.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=DevOpsCourse/OU=Lab5/CN=localhost"

echo "✅ Самоподписанный сертификат успешно сгенерирован в папке ./certs"