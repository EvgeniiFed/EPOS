# Lab 8: Kubernetes - Kustomize

Репозиторий для 8-й лабораторной работы по курсу DevOps.
На базе Lab 7 (Kubernetes Rolling Update) добавлена кастомизация с помощью Kustomize для dev и prod окружений.

## Что было сделано

### 1. Доработка приложения
- Добавлены переменные окружения `SERVER_NAME` и `ENV`
- На странице приветствия теперь отображается:
  - Имя сервера (из переменной окружения)
  - Окружение (dev/prod)
  - Hostname пода (для демонстрации балансировки)

### 2. Kustomize структура
Создана модульная структура с base и overlays:

```
k8s/
├── base/                    # Базовые манифесты
│   ├── kustomization.yaml
│   ├── redis-deployment.yaml
│   ├── redis-service.yaml
│   ├── flask-deployment.yaml
│   └── flask-service.yaml
└── overlays/
    ├── dev/                 # Dev окружение
    │   ├── kustomization.yaml
    │   ├── flask-deployment-patch.yaml
    │   └── flask-env.yaml
    └── prod/                # Prod окружение
        ├── kustomization.yaml
        ├── flask-deployment-patch.yaml
        ├── flask-env.yaml
        └── flask-replicas.yaml
```

### 3. Отличия окружений

| Параметр | Dev | Prod |
|----------|-----|------|
| Namespace | `dev` | `prod` |
| Name Prefix | `dev-` | `prod-` |
| Flask Replicas | 1 | 3 |
| SERVER_NAME | `dev-server` | `prod-server` |
| ENV | `development` | `production` |
| CPU Request | 100m | 200m |
| CPU Limit | 500m | 1000m |
| Memory Request | 128Mi | 256Mi |
| Memory Limit | 256Mi | 512Mi |

## Как использовать

### Предварительные требования
- Kubernetes кластер
- kubectl с настроенным доступом к кластеру
- Docker образ Flask

### Деплой Dev окружения

```bash
# Просмотр сгенерированных манифестов
kubectl kustomize k8s/overlays/dev/

# Применение в кластер
kubectl apply -k k8s/overlays/dev/

# Проверка
kubectl get all -n dev
```

### Деплой Prod окружения

```bash
# Просмотр сгенерированных манифестов
kubectl kustomize k8s/overlays/prod/

# Применение в кластер
kubectl apply -k k8s/overlays/prod/

# Проверка
kubectl get all -n prod
```

### Проверка работы

```bash
# Для dev
kubectl get svc -n dev
# Открой http://NODE_IP:30080

# Для prod
kubectl get svc -n prod
# Открой http://NODE_IP:30080

# Обновляй страницу несколько раз — увидишь разные hostname подов
```

### Удаление

```bash
# Удалить dev
kubectl delete -k k8s/overlays/dev/

# Удалить prod
kubectl delete -k k8s/overlays/prod/
```

## Демонстрация Rolling Update с Kustomize

### 1. Собери новую версию образа
```bash
cd app
docker build -t registry.puls.ru/epos/flask-app:v2 .
docker push registry.puls.ru/epos/flask-app:v2
```

### 2. Обнови образ в base манифесте
Открой `k8s/base/flask-deployment.yaml` и измени:
```yaml
image: registry.puls.ru/epos/flask-app:v2
```

### 3. Примени изменения
```bash
# Для dev
kubectl apply -k k8s/overlays/dev/

# Для prod
kubectl apply -k k8s/overlays/prod/
```

### 4. Наблюдай за rolling update
```bash
kubectl get pods -n dev -w
# или
kubectl get pods -n prod -w
```

## Преимущества Kustomize

1. **DRY (Don't Repeat Yourself)**: Base манифесты переиспользуются
2. **Декларативность**: Все изменения в YAML файлах
3. **Безопасность**: Можно просматривать результат перед применением (`kubectl kustomize`)
4. **Модульность**: Легко добавлять новые окружения (staging, test и т.д.)
5. **Интеграция**: Встроен в kubectl, не требует дополнительных инструментов

## Полезные команды

```bash
# Просмотр сгенерированных манифестов
kubectl kustomize k8s/overlays/dev/

# Применение
kubectl apply -k k8s/overlays/dev/

# Сравнение с текущим состоянием
kubectl diff -k k8s/overlays/dev/

# Удаление
kubectl delete -k k8s/overlays/dev/
```

## Проверка локально

```bash
# 1. Просмотри, что сгенерирует Kustomize для dev
kubectl kustomize k8s/overlays/dev/

# 2. Примени dev окружение
kubectl apply -k k8s/overlays/dev/

# 3. Проверь поды
kubectl get pods -n dev

# 4. Открой сервис и убедись, что видишь "dev-server" и "development"

# 5. Теперь примени prod
kubectl apply -k k8s/overlays/prod/

# 6. Проверь, что в prod 3 реплики и другие переменные окружения
kubectl get pods -n prod
kubectl get deployment prod-flask -n prod -o yaml | grep -A 10 "env:"
```
