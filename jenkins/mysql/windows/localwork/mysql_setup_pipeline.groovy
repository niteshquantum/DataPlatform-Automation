pipeline {

    agent any

    environment {
        PROJECT_ROOT = 'F:\\Quantumatrix\\Projects\\DataEng\\DataPlatform-Automation'
    }

    stages {

        stage('Validate Python Runtime') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\common\\validate_python_runtime.bat'
                }
            }
        }

        stage('Install Python Requirements') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\install_python_requirements.bat'
                }
            }
        }

        stage('Validate Python Requirements') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\validate_python_requirements.bat'
                }
            }
        }

        stage('Validate Java Runtime') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\common\\validate_java_runtime.bat'
                }
            }
        }

        stage('Install Tools') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\common\\install_tools.bat'
                }
            }
        }

        stage('Deploy MySQL') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\deploy_mysql.bat'
                }
            }
        }

        stage('Start MySQL') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\start_mysql.bat'
                }
            }
        }

        stage('Create Database') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\create_database.bat'
                }
            }
        }

        stage('Run Liquibase') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\run_liquibase.bat'
                }
            }
        }

        stage('Validate Environment') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\validate_environment.bat'
                }
            }
        }

        stage('Validate MySQL') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\validate_mysql.bat'
                }
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