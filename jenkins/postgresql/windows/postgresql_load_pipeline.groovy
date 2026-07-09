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
                bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start PostgreSQL Service') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
            }
        }

        stage('Validate PostgreSQL ') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\validate_postgresql.bat'
            }
        }

        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\load\\validate_loaded_data.bat'
            }
        }
    }

    post {

        success {
            echo 'POSTGRESQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'POSTGRESQL LOAD FAILED'
        }

        always {
            echo 'POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}