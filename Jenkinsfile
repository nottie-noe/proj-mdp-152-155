pipeline {
    agent any

    environment {
        IMAGE_NAME = 'nottiey/javacal-webapp'
        TAG = 'latest'
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: 'project-3', url: 'https://github.com/nottie-noe/proj-mdp-152-155.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'docker run --rm -v "$PWD":/app -w /app maven:3.8.5-openjdk-8 mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$TAG .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $IMAGE_NAME:$TAG
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                '''
            }
        }
    }

    post {
        success {
            echo "✅ App deployed successfully to Kubernetes!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}

