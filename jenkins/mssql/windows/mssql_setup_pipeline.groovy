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
                bat 'scripts\\batch\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\common\\install_tools.bat'
            }
        }

        stage('Install MSSQL Driver') {
            steps {
                bat 'scripts\\batch\\common\\install_mssql_driver.bat'
            }
        }

        stage('Deploy MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\deploy_mssql.bat'
            }
        }

        stage('Start MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\start_mssql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\mssql\\create_database.bat'
            }
        }

        stage('Run Liquibase') {
            steps {
                bat 'scripts\\batch\\mssql\\run_liquibase.bat'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\mssql\\validate_environment.bat'
            }
        }

        stage('Validate MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\validate_mssql.bat'
            }
        }
    }

    post {

        success {
            echo 'MSSQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'MSSQL SETUP FAILED'
        }

        always {
            echo 'MSSQL SETUP PIPELINE COMPLETED'
        }
    }
}