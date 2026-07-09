pipeline {

    agent any

    parameters {

        choice(
            name: 'CLEANUP_MODE',
            choices: [
                'PRESERVE_DATA',
                'DELETE_DATA'
            ],
            description: 'Select MySQL cleanup mode'
        )
    }

    environment {
        PIPELINE_TYPE = "MYSQL_WINDOWS_CLEANUP"
    }

    stages {

        stage('Cleanup Information') {

            steps {

                echo "====================================="
                echo "MYSQL WINDOWS CLEANUP PIPELINE"
                echo "====================================="

                echo "Workspace    : ${WORKSPACE}"
                echo "Cleanup Mode : ${params.CLEANUP_MODE}"
            }
        }

        stage('Validate Cleanup Scripts') {

            steps {

                bat '''
                @echo off

                if not exist "%WORKSPACE%\\scripts\\powershell\\mysql\\cleanup\\cleanup_mysql.ps1" (
                    echo ERROR: MySQL cleanup script not found
                    exit /b 1
                )

                echo MySQL cleanup scripts validated successfully
                '''
            }
        }

        stage('Cleanup MySQL') {

            steps {

                withEnv(["CLEANUP_MODE=${params.CLEANUP_MODE}"]) {

                    bat '''
                    @echo off

                    echo.
                    echo =====================================
                    echo RUNNING MYSQL CLEANUP
                    echo =====================================
                    echo.

                    powershell -NoProfile -ExecutionPolicy Bypass -File "%WORKSPACE%\\scripts\\powershell\\mysql\\cleanup\\cleanup_mysql.ps1"

                    if errorlevel 1 (
                        echo.
                        echo MYSQL CLEANUP FAILED
                        exit /b 1
                    )

                    echo.
                    echo MYSQL CLEANUP COMPLETED SUCCESSFULLY
                    '''
                }
            }
        }
    }

    post {

        success {

            echo "====================================="
            echo "MYSQL WINDOWS CLEANUP PIPELINE SUCCESSFUL"
            echo "====================================="
        }

        failure {

            echo "====================================="
            echo "MYSQL WINDOWS CLEANUP PIPELINE FAILED"
            echo "====================================="
        }

        always {

            echo "Cleanup Mode: ${params.CLEANUP_MODE}"
        }
    }
}