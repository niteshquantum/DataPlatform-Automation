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
                        echo 'Windows Service and Global PSQL configuration will be enabled.'

                    } else {

                        writeFile file: 'admin_status.txt', text: 'false'

                        echo 'Administrator privileges not available.'
                        echo 'Windows Service and Global PSQL configuration will be skipped.'
                        echo 'PostgreSQL will run using project-local configuration.'
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
                bat 'scripts\\batch\\postgresql\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\install_tools.bat'
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\deploy_postgresql.bat'
            }
        }

        stage('Configure PostgreSQL Service') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {
                echo 'Administrator privileges available.'
                echo 'Configuring PostgreSQL Windows Service...'

                bat 'scripts\\batch\\postgresql\\setup\\configure_postgresql_service.bat'
            }
        }

        stage('Start PostgreSQL') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() != 'true'
                }
            }

            steps {
                echo 'Administrator privileges unavailable.'
                echo 'Starting PostgreSQL in project-local mode...'

                bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\create_database.bat'
            }
        }

        stage('Run Liquibase') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\run_liquibase.bat'
            }
        }

        stage('Configure Global PSQL') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {
                echo 'Administrator privileges available.'
                echo 'Configuring Global PSQL command...'

                bat 'scripts\\batch\\postgresql\\setup\\configure_global_psql.bat'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\validate_environment.bat'
            }
        }
    }

    post {

        success {

            echo 'POSTGRESQL SETUP SUCCESSFUL'

            script {

                def adminResult = readFile('admin_status.txt').trim()

                if (adminResult == 'true') {

                    echo 'PostgreSQL Windows Service configured successfully.'
                    echo 'Global PSQL configuration completed successfully.'

                } else {

                    echo 'PostgreSQL configured successfully in project-local mode.'
                    echo 'Windows Service and Global PSQL configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }

        failure {
            echo 'POSTGRESQL SETUP FAILED'
        }

        always {
            echo 'POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}
