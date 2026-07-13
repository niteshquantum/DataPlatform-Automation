def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mongodb ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mongodb ^
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
                    --database mongodb ^
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

                        bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start MongoDB Service') {

            steps {

                script {

                    runTrackedStage(
                        'Start MongoDB Service'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\start_mongodb.bat'
                    }
                }
            }
        }


        stage('Validate MongoDB') {

            steps {

                script {

                    runTrackedStage(
                        'Validate MongoDB'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
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

                        bat 'scripts\\batch\\mongodb\\load\\load_data.bat'
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

                        bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }

        stage('Validate Collections') {
            steps {
                bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
            }
        }

        stage('Validate Indexes') {
            steps {
                bat 'scripts\\batch\\mongodb\\setup\\create_indexes.bat'
            }
        }

        stage('Assessment Inventories') {
            steps {
                bat 'scripts\\batch\\mongodb\\assessment\\run_assessment.bat all'
            }
        }

        stage('Final Assessment Report') {
            steps {
                bat 'scripts\\batch\\common\\generate_assessment_report.bat'
            }
        }
    }


    post {

        success {

            echo 'MONGODB LOAD SUCCESSFUL'
        }


        failure {

            echo 'MONGODB LOAD FAILED'
        }


        always {

            echo 'FINALIZING MONGODB LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/history/**, outputs/assessments/mongodb/**, outputs/assessments/assessment_report.json",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MONGODB LOAD PIPELINE COMPLETED'
        }
    }
}
