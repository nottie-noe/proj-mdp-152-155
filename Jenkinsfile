pipeline {
    agent any

    environment {
        KUBECONFIG = '/var/lib/jenkins/kubeconfig'
        IMAGE_NAME = 'nottiey/javacal-webapp'
        TAG = "${env.BUILD_NUMBER}"
        CLUSTER_NAME = 'prod-cluster.k8s.local'  // Update with your cluster name
        KOPS_STATE_STORE = 's3://kopscluster-state-bucket'  // Update with your S3 bucket
        AWS_REGION = 'us-east-1'  // Update your region
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: 'project-3', url: 'https://github.com/nottie-noe/proj-mdp-152-155.git'
            }
        }

        stage('Build with Maven (in Docker)') {
            steps {
                sh 'docker run --rm -v "$PWD":/app -w /app maven:3.8.1-openjdk-8 mvn clean package'
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
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh '''
                        echo "Setting KUBECONFIG from Jenkins credential..."
                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "Updating Kubernetes deployment YAML with image ${IMAGE_NAME}:${TAG}..."
                        sed -i "s|image:.*|image: ${IMAGE_NAME}:${TAG}|g" deployment.yml

                        echo "Verifying kubeconfig file..."
                        ls -l "$KUBECONFIG"
                        file "$KUBECONFIG"
                        cat "$KUBECONFIG"

                        echo "Testing cluster access..."
                        kubectl get nodes

                        echo "Deploying application..."
                        kubectl apply -f deployment.yml
            '''
        }
    }
}


    }

    post {
        success {
            script {
                def lb_dns = sh(
                    script: "kubectl get service calculator-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
                    returnStdout: true
                ).trim()
                
                echo "✅ Deployment successful! App should be live at http://${lb_dns}"
                
                mail to: 'thandonoe.ndlovu@gmail.com',
                     subject: "SUCCESS: Jenkins Build #${env.BUILD_NUMBER}",
                     body: "The Jenkins build was successful.\nApplication deployed at: http://${lb_dns}"
            }
        }

        failure {
            echo "❌ Pipeline failed!"
            mail to: 'thandonoe.ndlovu@gmail.com',
                 subject: "FAILURE: Jenkins Build #${env.BUILD_NUMBER}",
                 body: "The Jenkins build has failed. Please investigate the job: ${env.BUILD_URL}"
        }
    }
}


