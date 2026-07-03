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
                sh '''
                    find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                '''
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh 'bash scripts/bash/common/validate_python_runtime.sh'
            }
        }

        stage('Install Python Requirements') {
            steps {
                sh 'bash scripts/bash/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh 'bash scripts/bash/validate_python_requirements.sh'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh 'bash scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh 'bash scripts/bash/common/install_tools.sh'
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                sh 'bash scripts/bash/postgresql/deploy_postgresql.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh 'bash scripts/bash/postgresql/validate_postgresql.sh'
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

        always {
            sh 'find scripts/bash -type f -name "*.sh" -exec ls -l {} \\;'
        }
    }
}
