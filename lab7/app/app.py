from flask import Flask
from redis import Redis
from prometheus_flask_exporter import PrometheusMetrics
import os

app = Flask(__name__)
metrics = PrometheusMetrics(app)

redis_host = os.getenv('REDIS_HOST', 'redis-service')
redis_port = int(os.getenv('REDIS_PORT', 6379))
redis = Redis(host=redis_host, port=redis_port)

@app.route('/')
def hello():
    count = redis.incr('hits')
    return f'Привет! Я был посещен {count} раз.\n'

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)