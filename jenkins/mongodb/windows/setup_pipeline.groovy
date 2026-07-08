
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
                bat 'scripts\\batch\\mongodb\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\install_tools.bat'
            }
        }

        stage('Validate Tools') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_tools.bat'
            }
        }

        stage('Deploy MongoDB') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\run_terraform.bat'
            }
        }

        stage('Configure Global Mongosh') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\configure_global_mongosh.bat'
            }
        }

        stage('Configure MongoDB Service') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\configure_mongodb_service.bat'
            }
        }

        stage('Validate MongoDB') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
            }
        }

    }

    post {

        success {
            echo 'MONGODB SETUP SUCCESSFUL'
        }

        failure {
            echo 'MONGODB SETUP FAILED'
        }

        always {
            echo 'MONGODB SETUP PIPELINE COMPLETED'
        }
    }
}
