pipeline {
 
    agent any
 
    environment {

        PROJECT_ROOT = "/home/mohit/TeamD/DataPlatform-AutomationNitesh"

    }
 
    stages {
 
        stage('Set Permissions') {

            steps {

                sh '''

                cd "$PROJECT_ROOT"

                find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;

                '''

            }

        }
 
        stage('Validate Python Runtime') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/common/validate_python_runtime.sh"

            }

        }
 
        stage('Install Python Requirements') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/common/install_python_requirements.sh"

            }

        }
 
        stage('Validate Python Requirements') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/mongodb/setup/validate_python_requirements.sh"

            }

        }
 
        stage('Start MongoDB') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/mongodb/setup/start_mongodb.sh"

            }

        }
 
        stage('Validate MongoDB') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/mongodb/setup/validate_mongodb.sh"

            }

        }
 
        stage('Load Data') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/mongodb/load/load_data.sh"

            }

        }
 
        stage('Validate Loaded Data') {

            steps {

                sh "${PROJECT_ROOT}/scripts/bash/mongodb/load/validate_loaded_data.sh"

            }

        }

    }
 
    post {
 
        success {

            echo 'UBUNTU MONGODB LOAD SUCCESSFUL'

        }
 
        failure {

            echo 'UBUNTU MONGODB LOAD FAILED'

        }
 
        always {

            echo 'UBUNTU MONGODB LOAD PIPELINE COMPLETED'

        }

    }

}
 