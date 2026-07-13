def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mysql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mysql ^
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
                    --database mysql ^
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

                        bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start MySQL Service') {

            steps {

                script {

                    runTrackedStage(
                        'Start MySQL Service'
                    ) {

                        bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
                    }
                }
            }
        }


        stage('Validate MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Validate MySQL'
                    ) {

                        bat 'scripts\\batch\\mysql\\setup\\validate_mysql.bat'
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

                        bat 'scripts\\batch\\mysql\\load\\load_data.bat'
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

                        bat 'scripts\\batch\\mysql\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }

        stage('Deploy Views') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Views') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Functions') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Functions') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Triggers') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Triggers') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Assessment Inventories') {
            steps {
                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat all'
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

            echo 'MYSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'MYSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING MYSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/load/build_${env.BUILD_NUMBER}/**, reports/mysql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, outputs/assessments/mysql/**, outputs/assessments/assessment_report.json",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
