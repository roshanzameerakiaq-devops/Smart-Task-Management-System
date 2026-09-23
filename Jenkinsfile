pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'SonarScanner'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out Smart Task Management System'
            }
        }

        stage('Install Frontend Dependencies') {
            steps {
                sh '''
                    cd frontend
                    npm install
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                dir('frontend') {
                    withSonarQubeEnv('SonarQube') {
                        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                ${SCANNER_HOME}/bin/sonar-scanner \
                                -Dsonar.projectKey=smart-task-frontend \
                                -Dsonar.projectName="Smart Task Frontend" \
                                -Dsonar.sources=src \
                                -Dsonar.exclusions="**/node_modules/**,**/dist/**" \
                                -Dsonar.sourceEncoding=UTF-8 \
                                -Dsonar.login="$SONAR_TOKEN"
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                sh '''
                    cd frontend
                    npm run build
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    cd frontend
                    docker build -t smart-task-frontend:${BUILD_NUMBER} .
                    docker tag smart-task-frontend:${BUILD_NUMBER} smart-task-frontend:latest
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    docker rm -f smart-task-frontend-jenkins 2>/dev/null || true

                    docker run -d \
                        --name smart-task-frontend-jenkins \
                        -p 8082:80 \
                        smart-task-frontend:${BUILD_NUMBER}

                    sleep 5

                    curl -f http://localhost:8082

                    docker rm -f smart-task-frontend-jenkins
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
            echo 'Pipeline Finished'
        }

        success {
            echo 'CI/CD Pipeline Executed Successfully'
        }

        failure {
            echo 'CI/CD Pipeline Failed'
        }
    }
}
