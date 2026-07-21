def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mysql ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mysql ^
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
                    --database mysql ^
                    --action setup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MySQL Setup') {

            steps {

                script {

                    runTrackedStage(
                        'MySQL Setup'
                    ) {

                        bat 'scripts\\batch\\mysql\\mysql_setup_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MYSQL SETUP SUCCESSFUL'

            script {

                def adminResult = bat(
                    script: 'python scripts\\logging\\logger.py get-environment ^
                        --database mysql ^
                        --action setup ^
                        --build-number "${env.BUILD_NUMBER}" ^
                        --administrator-privileges',
                    returnStdout: true
                ).trim()

                if (adminResult == 'true') {

                    echo 'MySQL Windows Service configured successfully.'
                    echo 'Global MySQL configuration completed successfully.'

                } else {

                    echo 'MySQL configured successfully in project-local mode.'
                    echo 'Windows Service and Global MySQL configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }


        failure {

            echo 'MYSQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING MYSQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}
