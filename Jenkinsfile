pipeline {
    agent any

    environment {
        SCANNER_HOME = tool 'SonarScanner'
        HARBOR_REGISTRY = '43.205.113.13'
        HARBOR_PROJECT = 'smart-task'
        SONAR_PROJECT_KEY = 'smart-task-management-system'
        K8S_DEPLOY_ENABLED = 'false'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            "${SCANNER_HOME}/bin/sonar-scanner" \
                              -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                              -Dsonar.projectName="Smart Task Management System" \
                              -Dsonar.sources="frontend/src,api-gateway_1784010924579/src,auth-service_1784011000189/src,task-service/src,notification-service/src,report-service/src" \
                              -Dsonar.exclusions="**/node_modules/**,**/dist/**" \
                              -Dsonar.sourceEncoding=UTF-8 \
                              -Dsonar.token="$SONAR_TOKEN"
                        '''
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    set -e

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/frontend:${BUILD_NUMBER} \
                        frontend

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/api-gateway:${BUILD_NUMBER} \
                        api-gateway_1784010924579

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/auth-service:${BUILD_NUMBER} \
                        auth-service_1784011000189

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/task-service:${BUILD_NUMBER} \
                        task-service

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/notification-service:${BUILD_NUMBER} \
                        notification-service

                    docker build -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/report-service:${BUILD_NUMBER} \
                        report-service
                '''
            }
        }

        stage('Test Frontend Image') {
            steps {
                sh '''
                    set -e
                    docker rm -f smart-task-frontend-jenkins 2>/dev/null || true

                    docker run -d \
                        --name smart-task-frontend-jenkins \
                        -p 8082:80 \
                        ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/frontend:${BUILD_NUMBER}

                    sleep 5
                    curl -f http://localhost:8082

                    docker rm -f smart-task-frontend-jenkins
                '''
            }
        }

        stage('Push Images to Harbor') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'harbor-credentials',
                    usernameVariable: 'HARBOR_USER',
                    passwordVariable: 'HARBOR_PASSWORD'
                )]) {
                    sh '''
                        set -e

                        echo "$HARBOR_PASSWORD" | docker login "$HARBOR_REGISTRY" \
                            --username "$HARBOR_USER" \
                            --password-stdin

                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/frontend:${BUILD_NUMBER}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/api-gateway:${BUILD_NUMBER}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/auth-service:${BUILD_NUMBER}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/task-service:${BUILD_NUMBER}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/notification-service:${BUILD_NUMBER}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/report-service:${BUILD_NUMBER}

                        docker logout "$HARBOR_REGISTRY"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression {
                    return env.K8S_DEPLOY_ENABLED == 'true'
                }
            }
            steps {
                sh '''
                    set -e

                    kubectl create namespace smart-task \
                        --dry-run=client -o yaml | kubectl apply -f -

                    kubectl apply -f kubernetes/mongodb.yaml

                    helm upgrade --install api-gateway helm/api-gateway \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}

                    helm upgrade --install auth-service helm/auth-service \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}

                    helm upgrade --install task-service helm/task-service \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}

                    helm upgrade --install notification-service helm/notification-service \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}

                    helm upgrade --install report-service helm/report-service \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}

                    helm upgrade --install frontend helm/frontend \
                        --namespace smart-task \
                        --set image.tag=${BUILD_NUMBER}
                '''
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f || true'
            cleanWs()
        }

        success {
            echo 'Smart Task CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Smart Task CI/CD pipeline failed.'
        }
    }
}
