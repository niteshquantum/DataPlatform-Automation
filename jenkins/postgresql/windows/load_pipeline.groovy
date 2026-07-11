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

        stage('Deploy Views') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Views') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Functions') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Functions') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Triggers') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Triggers') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
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