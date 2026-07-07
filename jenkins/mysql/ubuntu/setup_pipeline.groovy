pipeline {

    agent any

    stages {

        stage('Set Permissions') {
            steps {
                sh '''
                find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
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
                sh './scripts/bash/mysql/setup/install_tools.sh'
            }
        }

        stage('Install MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/install_mysql.sh'
            }
        }

        stage('Deploy MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/deploy_mysql.sh'
            }
        }

        stage('Start MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/start_mysql.sh'
            }
        }

        stage('Create Database') {
            steps {
                sh './scripts/bash/mysql/setup/create_database.sh'
            }
        }

        stage('Configure Global MySQL') {
             steps {
                sh './scripts/bash/mysql/setup/configure_global_mysql.sh'
            }
        }
        stage('Validate Environment') {
            steps {
                sh './scripts/bash/mysql/setup/validate_environment.sh'
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