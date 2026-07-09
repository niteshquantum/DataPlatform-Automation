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

                    if (adminStatus == 0) {
                        env.HAS_ADMIN_PRIVILEGES = 'true'
                        echo 'Administrator privileges available.'
                        echo 'Windows Service and Global PSQL configuration will be enabled.'
                    } else {
                        env.HAS_ADMIN_PRIVILEGES = 'false'
                        echo 'Administrator privileges not available.'
                        echo 'Windows Service and Global PSQL configuration will be skipped.'
                        echo 'PostgreSQL will run using project-local configuration.'
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
                    env.HAS_ADMIN_PRIVILEGES == 'true'
                }
            }

            steps {
                bat 'scripts\\batch\\postgresql\\setup\\configure_postgresql_service.bat'
            }
        }

        stage('Start PostgreSQL') {

            when {
                expression {
                    env.HAS_ADMIN_PRIVILEGES == 'false'
                }
            }

            steps {
                bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\create_database.bat'
            }
        }

        stage('Configure Global PSQL') {

            when {
                expression {
                    env.HAS_ADMIN_PRIVILEGES == 'true'
                }
            }

            steps {
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
                if (env.HAS_ADMIN_PRIVILEGES == 'true') {
                    echo 'PostgreSQL Windows Service configured.'
                    echo 'Global PSQL configuration completed.'
                } else {
                    echo 'PostgreSQL configured in project-local mode.'
                    echo 'Windows Service and Global PSQL skipped because Administrator privileges were unavailable.'
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
