pipeline {

    agent any

    environment {
        ADMIN_STATUS = 'false'
    }

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

                        env.ADMIN_STATUS = "true"

                        echo 'Administrator privileges available.'

                    } else {

                        env.ADMIN_STATUS = "false"

                        echo 'Administrator privileges not available.'
                    }

                    echo "ADMIN STATUS = ${env.ADMIN_STATUS}"
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
                bat 'scripts\\batch\\mssql\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\install_tools.bat'
            }
        }

        stage('Deploy SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\deploy_mssql_gdrive.bat'
            }
        }

        stage('Configure SQL Server') {
            steps {

                echo 'Configuring SQL Server Network...'

                bat 'scripts\\batch\\mssql\\setup\\configure_mssql.bat'
            }
        }

        stage('Start SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\start_mssql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\create_database.bat'
            }
        }

        stage('Run Liquibase') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\run_liquibase.bat'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_environment.bat'
            }
        }

    }

    post {

        success {

            echo 'MSSQL SETUP SUCCESSFUL'

            script {

                if (env.ADMIN_STATUS == 'true') {
                    echo 'SQL Server network configuration completed successfully.'
                } else {
                    echo 'Administrator privileges were unavailable.'
                    echo 'SQL Server network configuration was skipped.'
                }
            }
        }

        failure {
            echo 'MSSQL SETUP FAILED'
        }

        always {
            echo 'PIPELINE COMPLETED'
        }
    }
}
