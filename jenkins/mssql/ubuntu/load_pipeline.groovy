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
                sh './scripts/bash/mssql/validate_tools.sh'
            }
        }

        stage('Validate SQL Server') {
            steps {
                sh './scripts/bash/mssql/validate_mssql.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/mssql/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mssql/validate_loaded_data.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU MSSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU MSSQL LOAD FAILED'
        }

        always {
            echo 'UBUNTU MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}