# Lab 7: Kubernetes - Rolling Update

Репозиторий для 7-й лабораторной работы по курсу DevOps.
Приложение Flask+Redis куберизировано с использованием Kubernetes Deployments и Services.

## Архитектура

### Компоненты:
- **Redis Deployment**: 1 реплика Redis для хранения счетчика посещений
- **Redis Service**: ClusterIP сервис для внутреннего доступа к Redis
- **Flask Deployment**: 2 реплики Flask-приложения с настроенным Rolling Update
- **Flask Service**: NodePort сервис для внешнего доступа к приложению (порт 30080)

### Особенности:
- Rolling Update стратегия: `maxSurge: 1`, `maxUnavailable: 0` (без простоя)
- Health checks (liveness и readiness probes)
- Resource limits для контроля потребления ресурсов

## Предварительные требования

1. Kubernetes кластер (minikube, k3s, или cloud provider)
2. kubectl настроен на работу с кластером
3. Docker Hub аккаунт для хранения образа

## Как запустить

### 1. Собери и запушь Docker-образ Flask
```bash
cd app
docker build -t registry.puls.ru/epos/flask-app:v1 .
docker push registry.puls.ru/epos/flask-app:v1
```

### 2. Обнови образ в манифесте
Открой `k8s/flask-deployment.yaml` и замени `YOUR_DOCKERHUB_USERNAME` на свой логин Docker Hub.

### 3. Деплой в Kubernetes
```bash
# Создаем Redis
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/redis-service.yaml

# Создаем Flask
kubectl apply -f k8s/flask-deployment.yaml
kubectl apply -f k8s/flask-service.yaml
```

### 4. Проверяем статус
```bash
# Смотрим поды
kubectl get pods

# Смотрим сервисы
kubectl get services

# Логи Flask-пода
kubectl logs -l app=flask
```

## Демонстрация Rolling Update

### 1. Собери новую версию образа
```bash
cd app
# Измени что-нибудь в app.py (например, добавь версию в приветствие)
docker build -t registry.puls.ru/epos/flask-app:v2 .
docker push registry.puls.ru/epos/flask-app:v2
```

### 2. Обнови Deployment
```bash
kubectl set image deployment/flask-deployment flask=registry.puls.ru/epos/flask-app:v2
```

### 3. Наблюдай за rolling update
```bash
# В реальном времени следи за статусом подов
kubectl get pods -w

# Или используй rollout status
kubectl rollout status deployment/flask-deployment
```

### 4. Проверь историю версий
```bash
kubectl rollout history deployment/flask-deployment
```

### 5. Откат к предыдущей версии
```bash
kubectl rollout undo deployment/flask-deployment
```

## Удаление ресурсов

```bash
kubectl delete -f k8s/
```