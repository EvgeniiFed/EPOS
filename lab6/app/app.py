from flask import Flask
from redis import Redis
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
# Инициализируем экспорт метрик Prometheus
metrics = PrometheusMetrics(app)

# Подключаемся к Redis
redis = Redis(host='redis', port=6379)

@app.route('/')
def hello():
    # Увеличиваем счетчик в Redis
    count = redis.incr('hits')
    return f'Привет! Я посетил {count} раз.\n'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)