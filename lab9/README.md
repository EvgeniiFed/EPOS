# Lab 9: Cloud-native Application с CI/CD Pipeline

Полноценное Cloud-native приложение Flask+Redis с автоматизированным CI/CD пайплайном на базе GitHub Actions и GitOps с ArgoCD.

## 📋 Содержание

1. [Описание проекта](#описание-проекта)
2. [Архитектура](#архитектура)
3. [Требования](#требования)
4. [Структура проекта](#структура-проекта)
5. [Локальный запуск](#локальный-запуск)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Kubernetes и Kustomize](#kubernetes-и-kustomize)
8. [ArgoCD и GitOps](#argocd-и-gitops)
9. [Демонстрация GitOps Workflow](#демонстрация-gitops-workflow)
10. [Полезные команды](#полезные-команды)

---

## 📖 Описание проекта

В рамках лабораторной работы реализовано:

✅ **Cloud-native приложение** на Flask с хранилищем в Redis  
✅ **Unit-тесты** с покрытием кода через pytest  
✅ **Multi-stage Docker build** для оптимизации образа  
✅ **CI Pipeline** в GitHub Actions (lint → test → build-test)  
✅ **CD Pipeline** с автоматической сборкой и пушем в Docker Hub  
✅ **Kubernetes манифесты** с Kustomize для dev/prod окружений  
✅ **ArgoCD** для GitOps-деплоя с автоматической синхронизацией  

---

## 🏗 Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                        Developer Workflow                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Repository (EPOS)                     │
│                  https://github.com/EvgeniiFed/EPOS             │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│      CI Pipeline         │    │      CD Pipeline         │
│  ┌────────────────────┐  │    │  ┌────────────────────┐  │
│  │ 1. Lint (flake8)   │  │    │  │ 1. Build Image     │  │
│  │ 2. Test (pytest)   │  │    │  │ 2. Push to Docker  │  │
│  │ 3. Build & Test    │  │    │  │    Hub             │  │
│  └────────────────────┘  │    └──────────────────────────┘
└──────────────────────────┘               │
                                           ▼
                          ┌──────────────────────────────┐
                          │     Docker Hub               │
                          │  devops9292/flask-app        │
                          │  Tags: latest, <git-sha>     │
                          └──────────────────────────────┘
                                           │
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         ArgoCD (GitOps)                         │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐   │
│  │  flask-app-dev          │  │  flask-app-prod             │   │
│  │  Sync: Automated        │  │  Sync: Automated            │   │
│  │  Auto-Prune + Self-Heal │  │  Auto-Prune + Self-Heal     │   │
│  └─────────────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster (minikube)                 │
│                                                                 │
│  ┌──────────────────────┐        ┌──────────────────────┐       │
│  │   Namespace: dev     │        │   Namespace: prod    │       │
│  │  ┌────────────────┐  │        │  ┌────────────────┐  │       │
│  │  │ Flask (1 pod)  │  │        │  │ Flask (2 pods) │  │       │
│  │  │ Redis (1 pod)  │  │        │  │ Redis (1 pod)  │  │       │
│  │  │ NodePort:30080 │  │        │  │ NodePort:30081 │  │       │
│  │  └────────────────┘  │        │  └────────────────┘  │       │
│  └──────────────────────┘        └──────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Требования

| Компонент | Версия | Назначение |
|-----------|--------|------------|
| Ubuntu | 24.04 | Хостовая ОС |
| Docker | 29.1.3 | Container runtime |
| minikube | 1.38.1 | Локальный Kubernetes кластер |
| kubectl | latest | Kubernetes CLI |
| argocd | latest | GitOps controller |
| Python | 3.9+ | Runtime для приложения |
| Git | latest | Система контроля версий |

---

## 📁 Структура проекта

```
lab9/
├── app/                              # Исходный код приложения
│   ├── app.py                        # Flask приложение
│   ├── requirements.txt              # Зависимости Python
│   └── Dockerfile                    # Multi-stage Dockerfile
├── tests/                            # Unit тесты
│   ├── requirements.txt              # Зависимости для тестов
│   └── test_app.py                   # Тесты pytest
├── k8s/                              # Kubernetes манифесты
│   ├── base/                         # Базовые манифесты
│   │   ├── kustomization.yaml
│   │   ├── redis-deployment.yaml
│   │   ├── redis-service.yaml
│   │   ├── flask-deployment.yaml
│   │   └── flask-service.yaml
│   └── overlays/                     # Оверлеи для окружений
│       ├── dev/                      # Development окружение
│       │   ├── kustomization.yaml
│       │   ├── flask-deployment-patch.yaml
│       │   └── flask-env.yaml
│       └── prod/                     # Production окружение
│           ├── kustomization.yaml
│           ├── flask-deployment-patch.yaml
│           ├── flask-env.yaml
│           ├── flask-replicas.yaml
│           └── flask-service-patch.yaml
├── .github/workflows/                # GitHub Actions
│   ├── ci.yaml                       # CI пайплайн
│   └── cd.yaml                       # CD пайплайн
├── .dockerignore
├── .gitignore
└── README.md
```

---

## 🚀 Локальный запуск

### 1. Установка зависимостей

```bash
# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей приложения
pip install -r app/requirements.txt

# Установка зависимостей для тестов
pip install -r tests/requirements.txt
```

### 2. Запуск тестов

```bash
pytest tests/ -v --cov=app --cov-report=term-missing
```

**Ожидаемый результат:**
```
tests/test_app.py::test_health_endpoint PASSED
tests/test_app.py::test_version_endpoint PASSED
tests/test_app.py::test_hello_endpoint PASSED
tests/test_app.py::test_hello_increments_counter PASSED
```

### 3. Сборка Docker образа

```bash
cd app
docker build -t flask-app:v1 .
```

### 4. Локальный запуск в Docker

```bash
# Запуск Redis
docker run -d --name redis-test redis:alpine

# Запуск Flask
docker run -d --name flask-test \
  --link redis-test:redis-service \
  -e REDIS_HOST=redis-service \
  -p 5000:5000 \
  flask-app:v1

# Проверка
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/version
```

---

## 🔄 CI/CD Pipeline

### CI Pipeline (`.github/workflows/ci.yaml`)

Запускается при push в ветки `main` и `dev`.

**Jobs:**
1. **Lint** - проверка кода с помощью flake8 и black
2. **Test** - запуск unit тестов с pytest
3. **Build-test** - сборка Docker образа и проверка health endpoint

```
lint → test → build-test
```

### CD Pipeline (`.github/workflows/cd.yaml`)

Запускается при push в `main` или `dev` при изменении файлов `lab9/app/**` или `lab9/k8s/**`.

**Jobs:**
1. **Build and Push** - сборка Docker образа и пуш в Docker Hub
   - Тег `latest` для ветки `main`
   - Тег `<git-sha>` для каждого коммита

**Необходимые GitHub Secrets:**
- `DOCKERHUB_USERNAME` - логин Docker Hub
- `DOCKERHUB_TOKEN` - токен Docker Hub

---

## ☸️ Kubernetes и Kustomize

### Сравнение окружений

| Параметр | Dev | Prod |
|----------|-----|------|
| Namespace | `dev` | `prod` |
| Name Prefix | `dev-` | `prod-` |
| Flask Replicas | 1 | 2 |
| SERVER_NAME | `dev-server` | `prod-server` |
| ENV | `development` | `production` |
| REDIS_HOST | `dev-redis-service` | `prod-redis-service` |
| APP_VERSION | `dev-v2.0.0` | `prod-v2.0.0` |
| NodePort | 30080 | 30081 |
| CPU Request | 100m | 200m |
| CPU Limit | 500m | 1000m |
| Memory Request | 128Mi | 256Mi |
| Memory Limit | 256Mi | 512Mi |

### Деплой через Kustomize

```bash
# Dev окружение
kubectl apply -k k8s/overlays/dev/

# Prod окружение
kubectl apply -k k8s/overlays/prod/

# Просмотр сгенерированных манифестов
kubectl kustomize k8s/overlays/dev/
```

---

## 🎯 ArgoCD и GitOps

### Установка ArgoCD

```bash
# Создание namespace
kubectl create namespace argocd

# Установка ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Получение пароля admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Открытие доступа через NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30443}]}}'
```

### Создание Applications

```bash
# Dev Application
argocd app create flask-app-dev \
  --repo https://github.com/EvgeniiFed/EPOS.git \
  --path k8s/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --insecure

# Prod Application
argocd app create flask-app-prod \
  --repo https://github.com/EvgeniiFed/EPOS.git \
  --path k8s/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --insecure
```

**Настройки синхронизации:**
- `--sync-policy automated` - автоматическая синхронизация при изменениях в Git
- `--auto-prune` - автоматическое удаление ресурсов, которых нет в Git
- `--self-heal` - автоматическое восстановление при ручных изменениях в кластере

---

## 🔄 Демонстрация GitOps Workflow

### Полный цикл обновления

```bash
# 1. Изменяем код приложения
sed -i "s|v2.0.0|v3.0.0|g" app/app.py

# 2. Обновляем версии в Kustomize overlays
sed -i 's|dev-v2.0.0|dev-v3.0.0|g' k8s/overlays/dev/flask-env.yaml
sed -i 's|prod-v2.0.0|prod-v3.0.0|g' k8s/overlays/prod/flask-env.yaml

# 3. Коммитим и пушим
git add .
git commit -m "Update to v3.0.0"
git push origin dev

# 4. Наблюдаем за GitHub Actions
# https://github.com/EvgeniiFed/EPOS/actions

# 5. ArgoCD автоматически обнаруживает изменения и деплоит
argocd app list

# 6. Проверяем обновление
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:30080/version  # Dev
curl http://$MINIKUBE_IP:30081/version  # Prod
```

---

## 🛠 Полезные команды

### Kubernetes

```bash
# Просмотр подов
kubectl get pods -n dev
kubectl get pods -n prod

# Просмотр сервисов
kubectl get svc -n dev
kubectl get svc -n prod

# Логи
kubectl logs -l app=flask -n dev
kubectl logs -f deployment/dev-flask -n dev

# Exec в под
kubectl exec -it deployment/dev-flask -n dev -- /bin/bash
```

### ArgoCD

```bash
# Список приложений
argocd app list

# Детальная информация
argocd app get flask-app-dev

# Ручная синхронизация
argocd app sync flask-app-dev

# Откат
argocd app rollback flask-app-dev

# Удаление
argocd app delete flask-app-dev
```

### Docker

```bash
# Локальная сборка
docker build -t flask-app:local ./app

# Просмотр образов
docker images | grep flask-app

# Запуск
docker run -p 5000:5000 flask-app:local
```

### Minikube

```bash
# Статус кластера
minikube status

# IP кластера
minikube ip

# Dashboard
minikube dashboard
```

---

## 🎓 Что было изучено

1. ✅ Создание Cloud-native приложения на Flask
2. ✅ Написание unit тестов с pytest и покрытием кода
3. ✅ Multi-stage Docker build с безопасностью
4. ✅ CI pipeline в GitHub Actions (lint → test → build-test)
5. ✅ Kubernetes манифесты с Kustomize для разных окружений
6. ✅ CD pipeline с автоматическим деплоем в Docker Hub
7. ✅ GitOps с ArgoCD и автоматической синхронизацией
8. ✅ Полный CI/CD workflow от кода до продакшена
