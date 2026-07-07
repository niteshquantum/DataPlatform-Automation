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
                bat 'scripts\\batch\\mssql\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install MSSQL Tools') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\install_mssql_tools.bat'
            }
        }

        stage('Debug Worker Hash') {
    steps {
        bat '''
        echo ===== WORKSPACE =====
        cd

        echo ===== REPOSITORY HASH =====
        powershell -Command "Get-FileHash scripts\\powershell\\mssql\\common\\elevated_runner.ps1"

        echo ===== PROGRAMDATA HASH =====
        powershell -Command "Get-FileHash C:\\ProgramData\\DataPlatformAutomation\\elevated_runner.ps1"

        echo ===== GIT COMMIT =====
        git rev-parse HEAD
        '''
    }
}

        stage('Deploy MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\deploy_mssql.bat'
            }
        }

        stage('Start MSSQL') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\start_mssql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\create_database.bat'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_environment.bat'
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