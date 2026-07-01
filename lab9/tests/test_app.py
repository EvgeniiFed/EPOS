import pytest
from unittest.mock import patch, MagicMock
import sys
import os

# Добавляем app в path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../app'))

@pytest.fixture
def client():
    """Фикстура для тестового клиента Flask"""
    # Мокаем Redis перед импортом app
    with patch('app.redis') as mock_redis:
        mock_redis.incr.return_value = 42
        
        from app import app
        app.config['TESTING'] = True
        
        with app.test_client() as client:
            yield client

def test_health_endpoint(client):
    """Тест эндпоинта /health"""
    response = client.get('/health')
    assert response.status_code == 200
    assert response.data == b'OK'

def test_version_endpoint(client):
    """Тест эндпоинта /version"""
    response = client.get('/version')
    assert response.status_code == 200
    assert b'Version:' in response.data

def test_hello_endpoint(client):
    """Тест главной страницы"""
    response = client.get('/')
    assert response.status_code == 200
    # Проверяем наличие ключевых слов (используем decode для UTF-8)
    response_text = response.data.decode('utf-8')
    assert 'Привет!' in response_text
    assert 'Я был посещен' in response_text
    assert 'Информация о сервере:' in response_text

def test_hello_increments_counter(client):
    """Тест что счетчик увеличивается"""
    with patch('app.redis') as mock_redis:
        mock_redis.incr.return_value = 100
        
        response = client.get('/')
        assert response.status_code == 200
        assert b'100' in response.data
        mock_redis.incr.assert_called_once_with('hits')
