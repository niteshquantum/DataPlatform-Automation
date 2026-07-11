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

  

        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
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

        stage('Download Dataset') {
            steps {
                sh './scripts/bash/common/download_dataset.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/postgresql/load/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/postgresql/load/validate_loaded_data.sh'
            }
        }

        stage('Deploy Views') {
            steps {
                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Views') {
            steps {
                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Functions') {
            steps {
                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Functions') {
            steps {
                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Triggers') {
            steps {
                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Triggers') {
            steps {
                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU POSTGRESQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU POSTGRESQL LOAD FAILED'
        }

        always {
            echo 'UBUNTU POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}
