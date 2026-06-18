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
                sh './scripts/bash/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/validate_python_requirements.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh './scripts/bash/common/install_tools.sh'
            }
        }

        stage('Validate Tools') {
            steps {
                sh './scripts/bash/common/validate_tools.sh'
            }
        }

        stage('Validate MySQL') {
            steps {
                sh './scripts/bash/mysql/validate_mysql.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/mysql/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mysql/validate_loaded_data.sh'
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