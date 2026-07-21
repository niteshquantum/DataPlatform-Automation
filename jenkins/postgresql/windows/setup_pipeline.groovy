def runTrackedStage(String stageName, String actionType = 'setup', Closure stageBody) {

    try {
        stageBody()
    } catch (Exception error) {
        throw error
    }
}

pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'DATABASE',
            choices: ['POSTGRESQL'],
            description: 'Select Database'
        )

        choice(
            name: 'ACTION',
            choices: ['SETUP'],
            description: 'Select Action'
        )
    }

    environment {
        PIPELINE_TYPE = "POSTGRESQL_WINDOWS_PIPELINE"
    }

    stages {

        stage('PostgreSQL Setup') {

            agent any

            when {
                allOf {
                    expression { params.DATABASE == 'POSTGRESQL' }
                    expression { params.ACTION == 'SETUP' }
                }
            }

            steps {

                checkout scm

                script {

                    runTrackedStage('PostgreSQL Setup', 'setup') {

                        bat 'scripts\\batch\\common\\validate_python_runtime.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\install_python_requirements.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
                        bat 'scripts\\batch\\common\\validate_java_runtime.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\install_tools.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\deploy_postgresql.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\configure_postgresql_service.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\create_database.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\run_liquibase.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\configure_global_psql.bat'
                        bat 'scripts\\batch\\postgresql\\setup\\validate_environment.bat'

                    }

                }

            }

        }

    }

    post {

        success {
            echo "====================================="
            echo "POSTGRESQL WINDOWS PIPELINE SUCCESSFUL"
            echo "====================================="
        }

        failure {
            echo "====================================="
            echo "POSTGRESQL WINDOWS PIPELINE FAILED"
            echo "====================================="
        }

        always {
            echo "PostgreSQL Pipeline Completed"
            echo "Action: ${params.ACTION}"
        }

    }

}