pipeline {
    agent any

    environment {
        DOCKER_USER = 'francyhsu123'
        IMAGE_NAME = 'product-service'
        IMAGE_TAG = "v1.0.${BUILD_NUMBER}"
    }

    stages {
        stage('Build') {
            steps {
                echo 'Installing dependencies and running linter...'
                sh 'pip install -r requirements.txt --break-system-packages'
                sh 'pip install flake8 --break-system-packages'
                sh 'flake8 src/ --max-line-length=120 || true'
            }
        }

        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh 'pip install pytest httpx --break-system-packages'
                sh 'python3 -m pytest tests/ -v'
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running SAST with Bandit...'
                sh 'pip install bandit pip-audit --break-system-packages'
                sh 'bandit -r src/ -f txt -o bandit-report.txt || true'
                echo 'Running dependency vulnerability scan with pip-audit...'
                sh 'pip-audit -r requirements.txt -f json -o pip-audit-report.json || true'
                sh 'pip-audit -r requirements.txt || true'
                archiveArtifacts artifacts: 'bandit-report.txt', allowEmptyArchive: true
                archiveArtifacts artifacts: 'pip-audit-report.json', allowEmptyArchive: true
            }
        }

        stage('Container Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest"
            }
        }

        stage('Container Security Scan') {
            steps {
                echo 'Scanning Docker image with Trivy...'
                sh """
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image \
                        --format json \
                        --output trivy-report.json \
                        --severity HIGH,CRITICAL \
                        ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} || true
                """
                sh """
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image \
                        --severity HIGH,CRITICAL \
                        ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} || true
                """
                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('Container Push') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    branch pattern: 'release/*', comparator: 'GLOB'
                }
            }
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh "echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'develop') {
                        echo 'Deploying to Dev environment...'
                    } else if (env.BRANCH_NAME?.startsWith('release/')) {
                        echo 'Deploying to Staging environment...'
                    } else if (env.BRANCH_NAME == 'main') {
                        echo 'Deploying to Production environment - approved automatically for demo.'
                    } else {
                        echo 'Build only - no deployment for feature branches.'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Image: ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
