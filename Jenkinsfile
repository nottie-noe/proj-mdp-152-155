pipeline {
    agent any

    environment {
        IMAGE_NAME = 'nottiey/javacal-webapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDS = 'docker-hub-credentials' // Credentials ID in Jenkins
    }

    triggers {
        pollSCM('* * * * *') // Check for changes every minute (you can adjust this)
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'project-1', url: 'https://github.com/nottie-noe/proj-mdp-152-155.git'
            }
        }

        stage('Build WAR using Docker Maven') {
            steps {
                echo 'Building WAR file using Maven in Docker...'
                sh '''
                    docker run --rm -v "$PWD":/app -w /app maven:3.8.5-openjdk-8 mvn clean package
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image from multi-stage Dockerfile...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy Container') {
            steps {
                echo 'Stopping and removing old container if it exists, then deploying new one...'
                sh '''
                    docker rm -f javacal-container || true
                    docker run -d --name javacal-container -p 8083:8080 ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success {
            echo "Build and deployment successful. App is running on http://<Jenkins-Server-IP>:8083"
        }
        failure {
            echo "Build or deployment failed. Check logs above."
        }
    }
}