pipeline {

    agent any

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

        stage('Display Cleanup Configuration') {

            steps {

                echo "======================================"
                echo "MONGODB WINDOWS CLEANUP PIPELINE"
                echo "======================================"
                echo "Pipeline Type : ${env.PIPELINE_TYPE}"
                echo "Cleanup Mode  : ${params.CLEANUP_MODE}"
                echo "Workspace     : ${env.WORKSPACE}"
                echo "======================================"
            }
        }

        stage('Validate Workspace') {

            steps {

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

        stage('Run MongoDB Cleanup') {

            steps {

                withEnv(["CLEANUP_MODE=${params.CLEANUP_MODE}"]) {

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

            echo "MongoDB cleanup pipeline execution finished."
        }
    }
}