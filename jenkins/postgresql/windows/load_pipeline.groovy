def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database postgresql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database postgresql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --failed-stage "${stageName}" ^
            --message "Stage execution failed"
        """

        throw error
    }
}


pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {

        stage('Initialize Logging') {

            steps {

                bat """
                    python scripts\\logging\\logger.py init ^
                    --database postgresql ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('Validate Python Runtime') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Python Runtime'
                    ) {

                        bat 'scripts\\batch\\common\\validate_python_runtime.bat'
                    }
                }
            }
        }


        stage('Validate Python Requirements') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Python Requirements'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start PostgreSQL Service') {

            steps {

                script {

                    runTrackedStage(
                        'Start PostgreSQL Service'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
                    }
                }
            }
        }


        stage('Validate PostgreSQL') {

            steps {

                script {

                    runTrackedStage(
                        'Validate PostgreSQL'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\validate_postgresql.bat'
                    }
                }
            }
        }


        stage('Download Dataset') {

            steps {

                script {

                    runTrackedStage(
                        'Download Dataset'
                    ) {

                        bat 'scripts\\batch\\common\\download_dataset.bat'
                    }
                }
            }
        }


        stage('Load Data') {

            steps {

                script {

                    runTrackedStage(
                        'Load Data'
                    ) {

                        bat 'scripts\\batch\\postgresql\\load\\load_data.bat'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Loaded Data'
                    ) {

                        bat 'scripts\\batch\\postgresql\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }

        stage('Deploy Views') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Views') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Functions') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Functions') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Triggers') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Triggers') {
            steps {
                bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
            }
        }

        stage('Database Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat database' } }
        stage('Schema Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat schema' } }
        stage('Table Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat table' } }
        stage('View Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat view' } }
        stage('Function Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat function' } }
        stage('Trigger Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat trigger' } }
        stage('Extension Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat extension' } }
        stage('Materialized View Inventory') { steps { bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat materialized_view' } }
        stage('Assessment Report') { steps { bat 'scripts\\batch\\common\\generate_assessment_report.bat' } }
    }


    post {

        success {

            echo 'POSTGRESQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'POSTGRESQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING POSTGRESQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, outputs/assessments/postgresql/**, outputs/assessments/assessment_report.json",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}
