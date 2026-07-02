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

        stage('Install Python Requirements') {
            steps {
                sh './scripts/bash/postgresql/setup/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh './scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh './scripts/bash/postgresql/setup/install_tools.sh'
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/deploy_postgresql.sh'
            }
        }

	stage('Install PostgreSQL') {
	    steps {
	        sh './scripts/bash/postgresql/setup/install_postgresql.sh'
	    }
	}

        stage('Start PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/start_postgresql.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_postgresql.sh'
            }
        }

        stage('Create Database') {
            steps {
                sh './scripts/bash/postgresql/setup/create_database.sh'
            }
        }

        stage('Validate Environment') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_environment.sh'
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
