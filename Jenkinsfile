pipeline {
    agent any

    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        IMAGE_NAME = 'nottiey/javacal-webapp'
        TAG = "${env.BUILD_NUMBER}"
        CLUSTER_NAME = 'prod-cluster.k8s.local'
        KOPS_STATE_STORE = 's3://kopscluster-state-bucket'
        AWS_REGION = 'us-east-1'
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
                withCredentials([
                    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE'),
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    script {
                        env.KUBECONFIG = "${KUBECONFIG_FILE}"
                        env.AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
                        env.AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
                    }

                    sh '''
                        echo "Setting KUBECONFIG..."
                        export KUBECONFIG="$KUBECONFIG_FILE"
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        echo "Updating deployment.yml with Docker image..."
                        sed -i "s|image:.*|image: ${IMAGE_NAME}:${TAG}|g" deployment.yml

                        echo "Validating Kubernetes context..."
                        kubectl config current-context
			echo "KUBECONFIG path: $KUBECONFIG"
  			ls -l $KUBECONFIG
  			cat $KUBECONFIG | grep "kind"
                        kubectl get nodes

                        echo "Deploying application..."
                        kubectl apply -f deployment.yml
                    '''

                    script {
                        env.lb_dns = sh(
                            script: 'kubectl get service calculator-service -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"',
                            returnStdout: true
                        ).trim()
                        echo "Fetched service hostname: ${env.lb_dns}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! App should be live at http://${env.lb_dns}"
            mail to: 'thandonoe.ndlovu@gmail.com',
                 subject: "SUCCESS: Jenkins Build #${env.BUILD_NUMBER}",
                 body: """\
The Jenkins build was successful.

Application deployed at:
http://${env.lb_dns}
"""
        }

        failure {
            echo "❌ Pipeline failed!"
            mail to: 'thandonoe.ndlovu@gmail.com',
                 subject: "FAILURE: Jenkins Build #${env.BUILD_NUMBER}",
                 body: """\
The Jenkins build has failed.
Please investigate the job at: ${env.BUILD_URL}
"""
        }
    }
}

