pipeline {

    agent any

    environment {
        PIPELINE_TYPE = "POSTGRESQL_SETUP"
        DATABASE      = "POSTGRESQL"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Repository Audit') {
            steps {
                sh 'ls -la'
            }
        }

        stage('Set Script Permissions') {
            steps {
                sh 'chmod -R +x scripts/bash/'
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh 'scripts/bash/common/validate_python_runtime.sh'
            }
        }

        stage('Install Python Requirements') {
            steps {
                sh 'scripts/bash/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh 'scripts/bash/validate_python_requirements.sh'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh 'scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh 'scripts/bash/common/install_tools.sh'
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                sh 'scripts/bash/postgresql/deploy_postgresql.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh 'scripts/bash/postgresql/validate_postgresql.sh'
            }
        }

    }

    post {
        success {
            echo 'PostgreSQL Setup Pipeline Completed Successfully'
        }
        failure {
            echo 'PostgreSQL Setup Pipeline Failed'
        }
    }
}