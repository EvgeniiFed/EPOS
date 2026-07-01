# Multi-stage build для оптимизации размера образа
FROM python:3.9-slim AS builder

WORKDIR /app

COPY requirements.txt .
# Устанавливаем пакеты в системную директорию (без --user)
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.9-slim

WORKDIR /app

# Копируем установленные пакеты из builder в системную директорию Python
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Копируем приложение
COPY app.py .

# Добавляем метаданные
LABEL maintainer="devops-course"
LABEL version="1.0"

EXPOSE 5000

# Запуск от непривилегированного пользователя
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD ["python", "app.py"]
