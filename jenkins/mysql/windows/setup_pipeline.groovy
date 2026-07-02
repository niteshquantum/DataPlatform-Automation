pipeline {

    agent any

    stages {

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Install Python Requirements') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\install_tools.bat'
            }
        }

        stage('Deploy MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\deploy_mysql.bat'
            }
        }

        stage('Start MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\create_database.bat'
            }
        }


        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_environment.bat'
            }
        }

    }

    post {

        success {
            echo 'MYSQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'MYSQL SETUP FAILED'
        }

        always {
            echo 'MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}