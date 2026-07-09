pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {

        stage('Check Administrator Privileges') {
            steps {
                script {

                    def adminStatus = bat(
                        script: 'scripts\\batch\\common\\check_admin_privileges.bat',
                        returnStatus: true
                    )

                    if (adminStatus == 0) {

                        writeFile file: 'admin_status.txt', text: 'true'

                        echo 'Administrator privileges available.'
                        echo 'Global Mongosh and MongoDB Service configuration will be enabled.'

                    } else {

                        writeFile file: 'admin_status.txt', text: 'false'

                        echo 'Administrator privileges not available.'
                        echo 'Global Mongosh and MongoDB Service configuration will be skipped.'
                        echo 'MongoDB will run using project-local mode.'
                    }

                    def adminResult = readFile('admin_status.txt').trim()

                    echo "ADMIN STATUS = ${adminResult}"
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
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {
                echo 'Administrator privileges available.'
                echo 'Configuring Global Mongosh command...'

                bat 'scripts\\batch\\mongodb\\setup\\configure_global_mongosh.bat'
            }
        }

        stage('Configure MongoDB Service') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {
                echo 'Administrator privileges available.'
                echo 'Configuring MongoDB Windows Service...'

                bat 'scripts\\batch\\mongodb\\setup\\configure_mongodb_service.bat'
            }
        }

        stage('Start MongoDB') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() != 'true'
                }
            }

            steps {
                echo 'Administrator privileges unavailable.'
                echo 'Starting MongoDB in project-local mode...'

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

                def adminResult = readFile('admin_status.txt').trim()

                if (adminResult == 'true') {

                    echo 'MongoDB Windows Service configured successfully.'
                    echo 'Global Mongosh configuration completed successfully.'

                } else {

                    echo 'MongoDB configured successfully in project-local mode.'
                    echo 'Windows Service and Global Mongosh configuration were skipped because Administrator privileges were unavailable.'
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
