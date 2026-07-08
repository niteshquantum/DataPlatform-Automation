pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {

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
                steps {
                    bat 'scripts\\batch\\postgresql\\setup\\configure_postgresql_service.bat'
                }
            }
            
            stage('Create Database') {
                steps {
                    bat 'scripts\\batch\\postgresql\\setup\\create_database.bat'
                }
            }
            
            stage('Configure Global PSQL') {
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
        }

        failure {
            echo 'POSTGRESQL SETUP FAILED'
        }

        always {
            echo 'POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}
