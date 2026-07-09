pipeline {

    agent any

    parameters {

        choice(
            name: 'CLEANUP_MODE',
            choices: [
                'PRESERVE_DATA',
                'DELETE_DATA'
            ],
            description: 'Select PostgreSQL cleanup mode'
        )
    }

    environment {
        PIPELINE_TYPE = "POSTGRESQL_WINDOWS_CLEANUP"
    }

    stages {

        stage('Cleanup Information') {

            steps {

                echo "====================================="
                echo "POSTGRESQL WINDOWS CLEANUP PIPELINE"
                echo "====================================="

                echo "Workspace    : ${WORKSPACE}"
                echo "Cleanup Mode : ${params.CLEANUP_MODE}"
            }
        }

        stage('Validate Cleanup Scripts') {

            steps {

                bat '''
                @echo off

                if not exist "%WORKSPACE%\\scripts\\batch\\postgresql\\cleanup\\postgresql_cleanup_pipeline.bat" (
                    echo ERROR: PostgreSQL cleanup pipeline not found
                    exit /b 1
                )

                if not exist "%WORKSPACE%\\scripts\\powershell\\postgresql\\cleanup\\stop_postgresql.ps1" (
                    echo ERROR: PostgreSQL stop script not found
                    exit /b 1
                )

                if not exist "%WORKSPACE%\\scripts\\powershell\\postgresql\\cleanup\\remove_postgresql.ps1" (
                    echo ERROR: PostgreSQL removal script not found
                    exit /b 1
                )

                if not exist "%WORKSPACE%\\scripts\\powershell\\postgresql\\cleanup\\reset_terraform_state.ps1" (
                    echo ERROR: PostgreSQL Terraform reset script not found
                    exit /b 1
                )

                if not exist "%WORKSPACE%\\scripts\\powershell\\postgresql\\cleanup\\validate_cleanup.ps1" (
                    echo ERROR: PostgreSQL cleanup validation script not found
                    exit /b 1
                )

                echo PostgreSQL cleanup scripts validated successfully
                '''
            }
        }

        stage('Cleanup PostgreSQL') {

            steps {

                withEnv(["CLEANUP_MODE=${params.CLEANUP_MODE}"]) {

                    bat '''
                    @echo off

                    echo.
                    echo =====================================
                    echo RUNNING POSTGRESQL CLEANUP
                    echo =====================================
                    echo.

                    call "%WORKSPACE%\\scripts\\batch\\postgresql\\cleanup\\postgresql_cleanup_pipeline.bat"

                    if errorlevel 1 (
                        echo.
                        echo POSTGRESQL CLEANUP FAILED
                        exit /b 1
                    )

                    echo.
                    echo POSTGRESQL CLEANUP COMPLETED SUCCESSFULLY
                    '''
                }
            }
        }
    }

    post {

        success {

            echo "====================================="
            echo "POSTGRESQL WINDOWS CLEANUP PIPELINE SUCCESSFUL"
            echo "====================================="
        }

        failure {

            echo "====================================="
            echo "POSTGRESQL WINDOWS CLEANUP PIPELINE FAILED"
            echo "====================================="
        }

        always {

            echo "Cleanup Mode: ${params.CLEANUP_MODE}"
        }
    }
}