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

        stage('Install Python Requirements') {
            steps {
                sh './scripts/bash/common/install_python_requirements.sh'
            }
        }

        stage('Start MongoDB') {
            steps {
                sh './scripts/bash/mongodb/setup/start_mongodb.sh'
            }
        }

        stage('Validate MongoDB') {
            steps {
                sh './scripts/bash/mongodb/setup/validate_mongodb.sh'
            }
        }

        stage('Download Dataset') {
            steps {
                sh './scripts/bash/common/download_dataset.sh'
            }
        }

        stage('Load MongoDB Data') {
            steps {
                sh './scripts/bash/mongodb/load/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mongodb/load/validate_loaded_data.sh'
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