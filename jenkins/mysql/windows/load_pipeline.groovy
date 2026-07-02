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
                bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start MySQL Service') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
            }
        }

        stage('Validate MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_mysql.bat'
            }
        }

       

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\validate_loaded_data.bat'
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