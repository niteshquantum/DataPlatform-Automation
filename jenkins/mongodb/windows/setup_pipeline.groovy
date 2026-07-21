def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mongodb ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mongodb ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --failed-stage "${stageName}" ^
            --message "Stage execution failed"
        """

        throw error
    }
}


pipeline {

    agent {
        label 'windows-node'
    }

    options {
        disableConcurrentBuilds()
    }


    stages {

        stage('Initialize Logging') {

            steps {

                bat """
                    python scripts\\logging\\logger.py init ^
                    --database mongodb ^
                    --action setup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MongoDB Setup') {

            steps {

                script {

                    runTrackedStage(
                        'MongoDB Setup'
                    ) {

                        bat 'scripts\\batch\\mongodb\\mongodb_setup_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MONGODB SETUP SUCCESSFUL'

            script {

                def adminResult = bat(
                    script: 'python scripts\\logging\\logger.py get-environment ^
                        --database mongodb ^
                        --action setup ^
                        --build-number "${env.BUILD_NUMBER}" ^
                        --administrator-privileges',
                    returnStdout: true
                ).trim()

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

            echo 'FINALIZING MONGODB SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mongodb ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mongodb/setup/build_${env.BUILD_NUMBER}/**, reports/mongodb/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MONGODB SETUP PIPELINE COMPLETED'
        }
    }
}
