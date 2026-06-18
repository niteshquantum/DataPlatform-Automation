pipeline {

    agent any

    stages {

        stage('Set Permissions') {
            steps {
                sh '''
                chmod +x scripts/bash/common/*.sh
                chmod +x scripts/bash/mongodb/*.sh
                '''
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh './scripts/bash/common/validate_python_runtime.sh'
            }
        }

        stage('Install Python Requirements') {
            steps {
                sh './scripts/bash/common/install_python_requirements.sh'
            }
        }

        stage('Install MongoDB') {
            steps {
                sh './scripts/bash/mongodb/install_mongodb.sh'
            }
        }

        stage('Install Mongosh') {
            steps {
                sh './scripts/bash/mongodb/install_mongosh.sh'
            }
        }

        stage('Start MongoDB') {
            steps {
                sh './scripts/bash/mongodb/start_mongodb.sh'
            }
        }

        stage('Validate MongoDB') {
            steps {
                sh './scripts/bash/mongodb/validate_mongodb.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MONGODB SETUP SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MONGODB SETUP FAILED'
        }

        always {
            echo 'UBUNTU MONGODB SETUP PIPELINE COMPLETED'
        }
    }
}