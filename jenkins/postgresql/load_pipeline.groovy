pipeline {

    agent any

    environment {
        PIPELINE_TYPE = "POSTGRESQL_LOAD"
        DATABASE      = "POSTGRESQL"
    }

    stages {

        stage('Repository Audit') {
            steps {
                bat 'dir'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\postgresql\\validate_environment.bat'
            }
        }

        stage('Generate Datasets') {
            steps {
                bat 'python scripts\\python\\postgresql\\generate_dataset.py'
            }
        }

        stage('Validate CSV Schema') {
            steps {
                bat 'python scripts\\python\\postgresql\\testcsvschema.py'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\validate_loaded_data.bat'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                bat 'scripts\\batch\\postgresql\\validate_postgresql.bat'
            }
        }

    }

    post {
        success {
            echo 'PostgreSQL Load Pipeline Completed Successfully'
        }
        failure {
            echo 'PostgreSQL Load Pipeline Failed'
        }
    }
}
