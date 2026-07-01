# test argocd
from flask import Flask
from redis import Redis
from prometheus_flask_exporter import PrometheusMetrics
import os
import socket

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Переменные окружения
redis_host = os.getenv('REDIS_HOST', 'redis-service')
redis_port = int(os.getenv('REDIS_PORT', 6379))
server_name = os.getenv('SERVER_NAME', 'unknown-server')
environment = os.getenv('ENV', 'development')

# Получаем hostname пода
hostname = socket.gethostname()

# Подключаемся к Redis
redis = Redis(host=redis_host, port=redis_port)

@app.route('/')
def hello():
    count = redis.incr('hits')
    return f'''Привет! Я был посещен {count} раз.

Информация о сервере:
- Server Name: {server_name}
- Environment: {environment}
- Pod Hostname: {hostname}
'''

@app.route('/health')
def health():
    return 'OK', 200

@app.route('/version')
def version():
    app_version = os.getenv('APP_VERSION', 'v2.0.0')
    return f'Version: {app_version}\n', 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
