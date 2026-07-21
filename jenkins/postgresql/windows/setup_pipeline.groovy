def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database postgresql ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database postgresql ^
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
                    --database postgresql ^
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

                        bat 'scripts\\batch\\postgresql\\postgresql_setup_pipeline.bat'
                    }
                }
            }
        }
        }


      



    post {

        success {

            echo 'POSTGRESQL SETUP SUCCESSFUL'

            script {

                def adminResult = readFile(
                    'admin_status.txt'
                ).trim()

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

            echo 'Mongodb SETUP FAILED'
        }


        always {

            echo 'FINALIZING POSTGRESQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }

            archiveArtifacts(
                artifacts: "logs/Postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/Postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'Postgresql SETUP PIPELINE COMPLETED'
        }
    }
}