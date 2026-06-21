FROM nginx:alpine

# Копируем статическую страницу
COPY index.html /usr/share/nginx/html/index.html

# Копируем кастомный конфиг Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Открываем порты
EXPOSE 80 443

# Запуск Nginx в foreground
CMD ["nginx", "-g", "daemon off;"]