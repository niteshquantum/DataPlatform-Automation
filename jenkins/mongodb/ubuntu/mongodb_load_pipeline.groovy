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

        stage('Install Python Requirements') {
            steps {
                sh './scripts/bash/common/install_python_requirements.sh'
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

        stage('Load MongoDB Data') {
            steps {
                sh './scripts/bash/mongodb/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mongodb/validate_loaded_data.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MONGODB LOAD SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MONGODB LOAD FAILED'
        }

        always {
            echo 'UBUNTU MONGODB LOAD PIPELINE COMPLETED'
        }
    }
}