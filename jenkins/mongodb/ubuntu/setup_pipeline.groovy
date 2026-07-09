pipeline {

    agent any

    stages {

      stage('Set Permissions') {
    steps {
        sh '''
        chmod -R +x scripts/bash
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
                sh './scripts/bash/mongodb/setup/install_mongodb.sh'
            }
        }

        stage('Install Mongosh') {
            steps {
                sh './scripts/bash/mongodb/setup/install_mongosh.sh'
            }
        }
        stage('Configure Global Mongosh') {
        steps {
            sh './scripts/bash/mongodb/setup/configure_global_mongosh.sh'
            }
        }
        stage('Start MongoDB') {
            steps {
                sh './scripts/bash/mongodb/setup/start_mongodb.sh'
            }
        }
        stage('Configure MongoDB Service') {
        steps {
            sh './scripts/bash/mongodb/setup/configure_mongodb_service.sh'
            }
        }
        stage('Validate MongoDB') {
            steps {
                sh './scripts/bash/mongodb/setup/validate_mongodb.sh'
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