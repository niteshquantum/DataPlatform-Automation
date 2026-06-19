pipeline {

    agent any

    stages {

        stage('Set Permissions') {
            steps {
                sh '''
                chmod +x scripts/bash/common/*.sh
                chmod +x scripts/bash/mssql/*.sh
                '''
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh './scripts/bash/common/validate_python_runtime.sh'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh './scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh './scripts/bash/common/install_tools.sh'
            }
        }

        stage('Install MSSQL Driver') {
            steps {
                sh './scripts/bash/common/install_mssql_driver.sh'
            }
        }

        stage('Install SQL Server') {
            steps {
                sh './scripts/bash/mssql/install_mssql.sh'
            }
        }

        stage('Install SQLCMD') {
            steps {
                sh './scripts/bash/mssql/install_sqlcmd.sh'
            }
        }

        stage('Start SQL Server') {
            steps {
                sh './scripts/bash/mssql/start_mssql.sh'
            }
        }

        stage('Create Database') {
            steps {
                sh './scripts/bash/mssql/create_database.sh'
            }
        }

        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/mssql/run_liquibase.sh'
            }
        }

        stage('Validate Environment') {
            steps {
                sh './scripts/bash/mssql/validate_environment.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MSSQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MSSQL SETUP FAILED'
        }

        always {
            echo 'UBUNTU MSSQL SETUP PIPELINE COMPLETED'
        }
    }
}