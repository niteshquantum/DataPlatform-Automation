pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        HAS_ADMIN_PRIVILEGES = 'false'
    }

    stages {

        stage('Check Administrator Privileges') {
            steps {
                script {

                    def adminStatus = bat(
                        script: 'scripts\\batch\\common\\check_admin_privileges.bat',
                        returnStatus: true
                    )

                    env.HAS_ADMIN_PRIVILEGES =
                        (adminStatus == 0) ? 'true' : 'false'

                    echo "HAS_ADMIN_PRIVILEGES = ${env.HAS_ADMIN_PRIVILEGES}"

                    if (env.HAS_ADMIN_PRIVILEGES == 'true') {

                        echo 'Administrator privileges available.'
                        echo 'Global Mongosh and MongoDB Service configuration will be enabled.'

                    } else {

                        echo 'Administrator privileges not available.'
                        echo 'Global Mongosh and MongoDB Service configuration will be skipped.'
                        echo 'MongoDB will run using project-local mode.'
                    }
                }
            }
        }

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Install Python Requirements') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\install_tools.bat'
            }
        }

        stage('Validate Tools') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_tools.bat'
            }
        }

        stage('Deploy MongoDB') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\run_terraform.bat'
            }
        }

        stage('Configure Global Mongosh') {

            when {
                expression {
                    env.HAS_ADMIN_PRIVILEGES == 'true'
                }
            }

            steps {
                bat 'scripts\\batch\\mongodb\\setup\\configure_global_mongosh.bat'
            }
        }

        stage('Configure MongoDB Service') {

            when {
                expression {
                    env.HAS_ADMIN_PRIVILEGES == 'true'
                }
            }

            steps {
                bat 'scripts\\batch\\mongodb\\setup\\configure_mongodb_service.bat'
            }
        }

        stage('Start MongoDB') {

            when {
                expression {
                    env.HAS_ADMIN_PRIVILEGES != 'true'
                }
            }

            steps {
                bat 'scripts\\batch\\mongodb\\setup\\start_mongodb.bat'
            }
        }

        stage('Validate MongoDB') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
            }
        }
    }

    post {

        success {

            echo 'MONGODB SETUP SUCCESSFUL'

            script {

                if (env.HAS_ADMIN_PRIVILEGES == 'true') {

                    echo 'MongoDB Windows Service configured.'
                    echo 'Global Mongosh configuration completed.'

                } else {

                    echo 'MongoDB configured in project-local mode.'
                    echo 'Windows Service and Global Mongosh skipped because Administrator privileges were unavailable.'
                }
            }
        }

        failure {
            echo 'MONGODB SETUP FAILED'
        }

        always {
            echo 'MONGODB SETUP PIPELINE COMPLETED'
        }
    }
}
