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
                bat 'scripts\\batch\\mssql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\start_mssql.bat'
            }
        }

        stage('Validate SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_mssql.bat'
            }
        }

        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mssql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mssql\\load\\validate_loaded_data.bat'
            }
        }

    }

    post {

        success {
            echo 'MSSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'MSSQL LOAD FAILED'
        }

        always {
            echo 'MSSQL LOAD PIPELINE COMPLETED'
        }

    }

}