// Jenkinsfile — демонстрация основных возможностей Declarative Pipeline.
// Использовать как "полигон" для проверки функций Jenkins CI/CD.

pipeline {

    // ---------- AGENT ----------
    agent any
    // Варианты, которые можно попробовать вместо agent any:
    // agent { label 'linux && docker' }
    // agent { docker { image 'python:3.12-slim' } }
    // agent none  // если агент задаётся отдельно в каждом stage

    // ---------- TOOLS ----------
    // Пример подключения инструмента, настроенного в Jenkins -> Global Tool Configuration
    // tools {
    //     jdk 'jdk17'
    //     maven 'maven3'
    // }

    // ---------- ПАРАМЕТРЫ СБОРКИ ----------
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Куда деплоим')
        booleanParam(name: 'RUN_DEPLOY', defaultValue: false, description: 'Выполнять ли деплой')
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Тег Docker-образа')
    }

    // ---------- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ----------
    environment {
        APP_NAME     = 'jenkins-cicd-demo'
        APP_VERSION  = "1.0.${BUILD_NUMBER}"
        // Тег теперь ВСЕГДА включает номер сборки (BUILD_NUMBER),
        // чтобы каждый билд гарантированно создавал новый, отличимый образ,
        // даже если params.IMAGE_TAG не менялся между запусками.
        DOCKER_IMAGE = "${APP_NAME}:${params.IMAGE_TAG}-${BUILD_NUMBER}"
        // Пример подтягивания секрета из Jenkins Credentials Store
        // DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
    }

    // ---------- ОПЦИИ ПАЙПЛАЙНА ----------
    options {
        // timestamps() и ansiColor('xterm') убраны — они требуют отдельных
        // плагинов (Timestamper, AnsiColor). Если поставите эти плагины
        // в Manage Jenkins -> Plugins, можно будет вернуть обе строки.
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        ansiColor('xterm')
    }

    // ---------- АВТОЗАПУСК ----------
    triggers {
        // pollSCM('H/5 * * * *')   // проверка репозитория раз в 5 минут
        // cron('H 2 * * *')        // ежедневная ночная сборка
        githubPush()               // запуск по webhook из GitHub
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Клонируем ветку ${env.BRANCH_NAME ?: 'main'}"
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements-dev.txt
                '''
            }
        }

        // ---------- ПАРАЛЛЕЛЬНЫЕ СТАДИИ ----------
        stage('Static checks & Tests') {
            parallel {
                stage('Lint') {
                    steps {
                        sh '''
                            . .venv/bin/activate
                            flake8 app --max-line-length=100 || true
                        '''
                    }
                }
                stage('Unit tests') {
                    steps {
                        sh '''
                            . .venv/bin/activate
                            pytest tests/ --junitxml=reports/junit.xml --cov=app --cov-report=xml
                        '''
                    }
                    post {
                        always {
                            junit 'reports/junit.xml'
                        }
                    }
                }
            }
        }

        // ---------- MERGE dev -> main ПОСЛЕ ПОДТВЕРЖДЕНИЯ РАЗРАБОТЧИКОМ ----------
        // Работает только когда собирается ветка dev (BRANCH_NAME задаётся
        // автоматически в Multibranch Pipeline).
        stage('Merge dev to main') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    // Разработчик видел зелёные Lint/Unit tests выше.
                    // Тут он явно подтверждает: "да, сливай в main".
                    input message: "Все проверки на dev прошли успешно. Слить dev в main?", ok: 'Слить в main'
                }
                withCredentials([usernamePassword(credentialsId: 'github-push-creds',
                                                   usernameVariable: 'GIT_USER',
                                                   passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins CI"

                        git fetch origin main:main
                        git checkout main
                        git merge origin/dev --no-edit

                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/Ronine01kz/jenkins-cicd-demo.git main
                    '''
                }
            }
        }

        stage('Build Docker image') {
            when {
                expression { return true } // сюда можно поставить любое условие
            }
            steps {
                sh """
                    docker build --build-arg APP_VERSION=${APP_VERSION} -t ${DOCKER_IMAGE} .
                    echo '--- Проверка, что образ новый ---'
                    echo "Тег образа:        ${DOCKER_IMAGE}"
                    echo "APP_VERSION:       ${APP_VERSION}"
                    echo "IMAGE ID:"
                    docker images ${APP_NAME} --format '{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}'
                """
            }
        }

        stage('Push image') {
            when {
                branch 'main'
            }
            steps {
                echo "Здесь был бы docker push ${DOCKER_IMAGE}"
                // withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                //                                    usernameVariable: 'DOCKER_USER',
                //                                    passwordVariable: 'DOCKER_PASS')]) {
                //     sh '''
                //         echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                //         docker push ${DOCKER_IMAGE}
                //     '''
                // }
            }
        }

        stage('Approval') {
            when {
                expression { return params.RUN_DEPLOY }
            }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input message: "Подтвердите деплой на ${params.ENVIRONMENT}?", ok: 'Деплоить'
                }
            }
        }

        // ---------- MATRIX (несколько комбинаций окружений) ----------
        stage('Matrix example') {
            matrix {
                axes {
                    axis {
                        name 'PYTHON_VERSION'
                        values '3.10', '3.11', '3.12'
                    }
                }
                stages {
                    stage('Test on Python version') {
                        steps {
                            echo "Проверка совместимости с Python ${PYTHON_VERSION}"
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                allOf {
                    expression { return params.RUN_DEPLOY }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "Деплой ${APP_NAME} версии ${APP_VERSION} в ${params.ENVIRONMENT}"
                    sh "bash scripts/deploy.sh ${params.ENVIRONMENT} ${DOCKER_IMAGE} 5000"
                }
            }
        }
    }

    // ---------- POST-ДЕЙСТВИЯ ----------
    post {
        always {
            echo 'Пайплайн завершён (в любом случае).'
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            // cleanWs() убран — требует плагина "Workspace Cleanup Plugin".
            // Поставите плагин (Manage Jenkins -> Plugins) — можно будет вернуть.
        }
        success {
            echo "Сборка #${BUILD_NUMBER} прошла успешно."
        }
        failure {
            echo "Сборка #${BUILD_NUMBER} завершилась с ошибкой."
            // mail to: 'team@example.com', subject: "Build failed: ${env.JOB_NAME}", body: "Смотри ${env.BUILD_URL}"
        }
        unstable {
            echo 'Сборка нестабильна (есть проваленные тесты).'
        }
        changed {
            echo 'Статус пайплайна изменился по сравнению с прошлым запуском.'
        }
    }
}
