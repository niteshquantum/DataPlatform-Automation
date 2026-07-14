def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mongodb ^
        --action cleanup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action cleanup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action cleanup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mongodb ^
            --action cleanup ^
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

    parameters {

        choice(
            name: 'CLEANUP_MODE',
            choices: [
                'PRESERVE_DATA',
                'DELETE_DATA'
            ],
            description: 'Select MongoDB cleanup mode'
        )
    }

    environment {

        PIPELINE_TYPE = "MONGODB_WINDOWS_CLEANUP"
    }


    stages {

        stage('Initialize Logging') {

            steps {

                bat """
                    python scripts\\logging\\logger.py init ^
                    --database mongodb ^
                    --action cleanup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('Display Cleanup Configuration') {

            steps {

                script {

                    runTrackedStage(
                        'Display Cleanup Configuration'
                    ) {

                        echo "======================================"
                        echo "MONGODB WINDOWS CLEANUP PIPELINE"
                        echo "======================================"
                        echo "Pipeline Type : ${env.PIPELINE_TYPE}"
                        echo "Cleanup Mode  : ${params.CLEANUP_MODE}"
                        echo "Workspace     : ${env.WORKSPACE}"
                        echo "======================================"
                    }
                }
            }
        }


        stage('Validate Workspace') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Workspace'
                    ) {

                        bat '''
                            @echo off

                            echo.
                            echo =====================================
                            echo VALIDATING JENKINS WORKSPACE
                            echo =====================================
                            echo.

                            if not exist "scripts\\batch\\mongodb\\cleanup\\mongodb_cleanup_pipeline.bat" (
                                echo ERROR: MongoDB cleanup pipeline not found.
                                exit /b 1
                            )

                            if not exist "config\\windows\\mongodb.conf" (
                                echo ERROR: MongoDB configuration file not found.
                                exit /b 1
                            )

                            if not exist "terraform\\mongodb" (
                                echo ERROR: MongoDB Terraform directory not found.
                                exit /b 1
                            )

                            echo MongoDB cleanup workspace validation successful.
                        '''
                    }
                }
            }
        }


        stage('Run MongoDB Cleanup') {

            steps {

                script {

                    runTrackedStage(
                        'Run MongoDB Cleanup'
                    ) {

                        withEnv([
                            "CLEANUP_MODE=${params.CLEANUP_MODE}"
                        ]) {

                            bat '''
                                @echo off

                                echo.
                                echo =====================================
                                echo RUNNING MONGODB WINDOWS CLEANUP
                                echo =====================================
                                echo.

                                call scripts\\batch\\mongodb\\cleanup\\mongodb_cleanup_pipeline.bat

                                if errorlevel 1 (
                                    echo.
                                    echo =====================================
                                    echo MONGODB CLEANUP FAILED
                                    echo =====================================
                                    echo.
                                    exit /b 1
                                )

                                echo.
                                echo =====================================
                                echo MONGODB CLEANUP COMPLETED
                                echo =====================================
                                echo.
                            '''
                        }
                    }
                }
            }
        }
    }


    post {

        success {

            echo "======================================"
            echo "MONGODB WINDOWS CLEANUP SUCCESSFUL"
            echo "Cleanup Mode : ${params.CLEANUP_MODE}"
            echo "======================================"
        }


        failure {

            echo "======================================"
            echo "MONGODB WINDOWS CLEANUP FAILED"
            echo "Cleanup Mode : ${params.CLEANUP_MODE}"
            echo "======================================"
        }


        always {

            echo 'FINALIZING MONGODB CLEANUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mongodb ^
                    --action cleanup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mongodb ^
                    --action cleanup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mongodb ^
                    --action cleanup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mongodb/cleanup/build_${env.BUILD_NUMBER}/**, reports/mongodb/cleanup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo "Cleanup Mode: ${params.CLEANUP_MODE}"
            echo 'MONGODB CLEANUP PIPELINE COMPLETED'
        }
    }
}