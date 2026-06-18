pipeline {

    agent any

    stages {

        stage('Set Permissions') {
            steps {
                sh '''
                chmod +x scripts/bash/common/*.sh
                chmod +x scripts/bash/mysql/*.sh
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

        stage('Install MySQL') {
            steps {
                sh './scripts/bash/mysql/install_mysql.sh'
            }
        }

        stage('Start MySQL') {
            steps {
                sh './scripts/bash/mysql/start_mysql.sh'
            }
        }

        stage('Create Database') {
            steps {
                sh './scripts/bash/mysql/create_database.sh'
            }
        }

        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/mysql/run_liquibase.sh'
            }
        }

        stage('Validate Environment') {
            steps {
                sh './scripts/bash/mysql/validate_environment.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MYSQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MYSQL SETUP FAILED'
        }

        always {
            echo 'UBUNTU MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}