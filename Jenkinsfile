pipeline {
    agent any

    environment {
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
                withCredentials([
                    file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG'),
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    script {
                        // Create a persistent kubeconfig file
                        sh "cp ${KUBECONFIG} ./kubeconfig"
                        env.KUBECONFIG = "${WORKSPACE}/kubeconfig"
                        
                        sh """
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                        export AWS_REGION=${AWS_REGION}
                        
                        # Refresh credentials with longer validity
                        kops export kubecfg --name ${CLUSTER_NAME} \
                            --state ${KOPS_STATE_STORE} \
                            --admin=87600h  # 10-year validity
                        
                        # Update deployment
                        sed -i "s|image:.*|image: ${IMAGE_NAME}:${TAG}|g" deployment.yml
                        
                        # Apply configuration with validation skip
                        kubectl apply -f deployment.yml --validate=false
                        kubectl apply -f service.yml
                        
                        # Check rollout status
                        kubectl rollout status deployment/calculator-deployment
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_REGION=${AWS_REGION}
                    export KUBECONFIG=${WORKSPACE}/kubeconfig
                    
                    # Refresh credentials again
                    kops export kubecfg --name ${CLUSTER_NAME} \
                        --state ${KOPS_STATE_STORE} \
                        --admin=87600h
                    
                    # Get LB DNS
                    LB_DNS=\$(kubectl get service calculator-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                    echo "✅ Deployment successful! App should be live at http://\$LB_DNS" > lb_dns.txt
                    """
                    
                    def lb_dns = readFile('lb_dns.txt').trim()
                    echo lb_dns
                    mail to: 'thandonoe.ndlovu@gmail.com',
                         subject: "SUCCESS: Jenkins Build #${env.BUILD_NUMBER}",
                         body: "The Jenkins build was successful.\nApplication deployed at: ${lb_dns}"
                }
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
