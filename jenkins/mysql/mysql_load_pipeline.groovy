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

        stage('Validate MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\validate_mysql.bat'
            }
        }

        stage('Validate CSV') {
            steps {
                bat 'scripts\\batch\\mysql\\validate_csv.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mysql\\validate_loaded_data.bat'
            }
        }
    }

    post {

        success {
            echo 'MYSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'MYSQL LOAD FAILED'
        }

        always {
            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}