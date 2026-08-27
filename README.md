
# jenkins-cicd-demo
#uhfjgnjnjnjmsaMDKMMDW7RY 7HYYEUVIOW0IVUBYTREMI,ODO0EMINUR MKMFKSD
Тестовый репозиторий для проверки возможностей Jenkins CI/CD (Declarative Pipeline).

## Что внутри

- `app/` — простое Flask-приложение (`app.py`, `requirements.txt`)
- `tests/` — юнит-тесты на pytest
- `Jenkinsfile` — пайплайн, демонстрирующий:
  - `parameters` (choice, boolean, string)
  - `environment` переменные и `credentials()`
  - `options` (timestamps, timeout, buildDiscarder, disableConcurrentBuilds, ansiColor)
  - `triggers` (pollSCM, cron, githubPush)
  - параллельные стадии (`parallel`)
  - условные стадии (`when { branch }`, `when { expression }`, `allOf`)
  - `input` (ручное подтверждение перед деплоем)
  - `matrix` (сборка на нескольких версиях Python)
  - `junit` отчёты и `archiveArtifacts`
  - `post { always / success / failure / unstable / changed }`
  - Docker build (Dockerfile прилагается)
- `Dockerfile`, `docker-compose.yml` — контейнеризация приложения
- `scripts/deploy.sh` — заглушка деплой-скрипта под dev/staging/production
- `k8s/dev/deployment.yaml` — пример манифеста Kubernetes

## Как загрузить в GitHub

```bash
cd jenkins-cicd-demo
git init
git add .
git commit -m "Initial commit: Jenkins CI/CD demo"
git branch -M main
git remote add origin https://github.com/<ваш-логин>/jenkins-cicd-demo.git
git push -u origin main
```

## Как подключить к Jenkins

1. В Jenkins: **New Item → Pipeline** (или **Multibranch Pipeline**, если хотите, чтобы Jenkins сам подхватывал ветки/PR).
2. В разделе **Pipeline** выберите **Pipeline script from SCM**.
3. SCM: **Git**, укажите URL вашего репозитория и учётные данные (если репозиторий приватный — добавьте их в **Manage Jenkins → Credentials**).
4. Script Path: `Jenkinsfile` (по умолчанию).
5. Если хотите автозапуск по пушу — настройте GitHub webhook на `http://<jenkins-host>/github-webhook/` и включите в репозитории GitHub интеграцию (плагин **GitHub Integration Plugin** должен быть установлен в Jenkins).
6. Запустите билд вручную (**Build with Parameters**) — увидите параметры `ENVIRONMENT`, `RUN_DEPLOY`, `IMAGE_TAG`.

## Локальный запуск без Jenkins

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest tests/
python app/app.py
```

или через Docker:

```bash
docker compose up --build
```

## Что стоит донастроить под себя

- Раскомментировать и настроить `credentials('dockerhub-creds')`, если нужен push образа в registry.
- Заменить заглушки в `scripts/deploy.sh` на реальные команды (`kubectl`, `helm`, `ansible` и т.д.).
- При необходимости заменить `agent any` на `agent { docker { image '...' } }`, если Jenkins-агент не имеет предустановленного Python.
- Установить в Jenkins плагины: Pipeline, Git, JUnit, Docker Pipeline, AnsiColor, Credentials Binding (для примеров выше).
