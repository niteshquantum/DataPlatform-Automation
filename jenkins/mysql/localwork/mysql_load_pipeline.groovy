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

        stage('Validate Python Requirements') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\validate_python_requirements.bat'
                }
            }
        }

        stage('Validate Tools') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\common\\validate_tools.bat'
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

        stage('Validate CSV') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\validate_csv.bat'
                }
            }
        }

        stage('Load Data') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\load_data.bat'
                }
            }
        }

        stage('Validate Loaded Data') {
            steps {
                dir("${PROJECT_ROOT}") {
                    bat 'scripts\\batch\\mysql\\validate_loaded_data.bat'
                }
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