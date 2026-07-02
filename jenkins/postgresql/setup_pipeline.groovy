pipeline {

    agent any

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Repository Audit') {
            steps {
                sh '''
                echo "Workspace : $WORKSPACE"
                echo "Branch    : $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
                echo "Commit    : $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
                ls -la
                '''
            }
        }

        stage('Set Script Permissions') {
            steps {
                sh '''
                chmod -R +x scripts/bash/
                '''
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh './scripts/bash/common/validate_python_runtime.sh'
            }
        }

        stage('Install Python Requirements') {
            steps {
                sh '''
                python3 -m pip install --break-system-packages psycopg2-binary pandas || \
                python3 -m pip install psycopg2-binary pandas
                '''
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh '''
                python3 -c "import psycopg2; print('psycopg2 OK:', psycopg2.__version__)"
                python3 -c "import pandas; print('pandas OK:', pandas.__version__)"
                '''
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh './scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh '''
                bash scripts/bash/common/install_liquibase.sh || true
                '''
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/install_postgresql.sh'
                sh './scripts/bash/postgresql/start_postgresql.sh'
                sh './scripts/bash/postgresql/create_database.sh'
                sh './scripts/bash/postgresql/run_liquibase.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/validate_postgresql.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU POSTGRESQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU POSTGRESQL SETUP FAILED'
        }

        always {
            echo 'UBUNTU POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}