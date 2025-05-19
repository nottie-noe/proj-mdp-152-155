pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = "javacal"
        TOMCAT_SERVER_IP = "54.86.21.245"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'project-1', 
                     url: 'https://github.com/nottie-noe/proj-mdp-152-155.git'
            }
        }
        
        stage('Build with Docker') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${env.BUILD_ID}")
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-creds') {
                        docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").push()
                        docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Tomcat') {
            steps {
                sshagent(['tomcat-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${TOMCAT_SERVER_IP} \
                    "docker pull ${DOCKER_IMAGE}:latest && \
                    docker stop calculator-app || true && \
                    docker rm calculator-app || true && \
                    docker run -d --name calculator-app -p 8083:8080 ${DOCKER_IMAGE:latest}
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            slackSend color: 'good', message: "Build ${env.BUILD_NUMBER} succeeded!"
        }
        failure {
            slackSend color: 'danger', message: "Build ${env.BUILD_NUMBER} failed!"
        }
    }
}