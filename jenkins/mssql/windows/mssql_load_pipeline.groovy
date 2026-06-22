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
                bat 'scripts\\batch\\validate_python_requirements.bat'
            }
        }

        stage('Validate Tools') {
            steps {
                bat 'scripts\\batch\\common\\validate_tools.bat'
            }
        }

        stage('Validate MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\validate_mssql.bat'
            }
        }

        stage('Validate CSV') {
            steps {
                bat 'scripts\\batch\\mssql\\validate_csv.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mssql\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mssql\\validate_loaded_data.bat'
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