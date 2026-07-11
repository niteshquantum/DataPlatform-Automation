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
                sh './scripts/bash/mysql/setup/validate_python_requirements.sh'
            }
        }

        stage('Start MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/start_mysql.sh'
            }
        }

        stage('Validate MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/validate_mysql.sh'
            }
        }


        stage('Download Dataset') {
            steps {
                sh './scripts/bash/common/download_dataset.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/mysql/load/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mysql/load/validate_loaded_data.sh'
            }
        }

        stage('Deploy Views') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Views') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Functions') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Functions') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Triggers') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Triggers') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MYSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MYSQL LOAD FAILED'
        }

        always {
            echo 'UBUNTU MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
