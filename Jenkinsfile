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
                echo 'Running security scan...'
                sh 'pip install bandit --break-system-packages'
                sh 'bandit -r src/ -f txt -o bandit-report.txt || true'
                archiveArtifacts artifacts: 'bandit-report.txt', allowEmptyArchive: true
            }
        }

        stage('Container Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest"
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
