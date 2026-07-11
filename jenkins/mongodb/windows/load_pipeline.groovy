pipeline {

    agent any

    stages {

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start MongoDB Service') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\start_mongodb.bat'
            }
        }

        stage('Validate MongoDB') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
            }
        }

        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mongodb\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
            }
        }

        stage('Validate Collections') {
            steps {
                bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
            }
        }

        stage('Validate Indexes') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\create_indexes.bat'
            }
        }
    }

    post {

        success {
            echo 'MONGODB LOAD SUCCESSFUL'
        }

        failure {
            echo 'MONGODB LOAD FAILED'
        }

        always {
            echo 'MONGODB LOAD PIPELINE COMPLETED'
        }
    }
}
