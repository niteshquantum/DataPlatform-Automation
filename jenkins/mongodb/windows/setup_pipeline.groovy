def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database Mongodb ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database Mongodb ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database Mongodb ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database Mongodb ^
            --action setup ^
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
                    --database Mongodb ^
                    --action setup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('Mongodb Setup') {

            steps {

                script {

                    runTrackedStage(
                        'Mongodb Setup'
                    ) {

                        bat 'ObjectsTanisha\scripts\batch\mongodb\mongodb_setup_pipeline.bat'
                    }
                }
            }
        }
        }


      



    post {

        success {

            echo 'mongodb SETUP SUCCESSFUL'

            script {

                def adminResult = readFile(
                    'admin_status.txt'
                ).trim()

                if (adminResult == 'true') {

                    echo 'Mongodb Windows Service configured successfully.'
                    echo 'Global mongosh configuration completed successfully.'

                } else {

                    echo 'Mongodb configured successfully in project-local mode.'
                    echo 'Windows Service and Global mongosh configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }


        failure {

            echo 'Mongodb SETUP FAILED'
        }


        always {

            echo 'FINALIZING Mongodb SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database Mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database Mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database Mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }

            archiveArtifacts(
                artifacts: "logs/Mongodb/setup/build_${env.BUILD_NUMBER}/**, reports/Mongodb/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'Mongodb SETUP PIPELINE COMPLETED'
        }
    }
}