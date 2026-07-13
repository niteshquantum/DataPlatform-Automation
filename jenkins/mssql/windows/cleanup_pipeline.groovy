pipeline {

    agent any

    parameters {

        choice(
            name: 'CLEANUP_MODE',
            choices: [
                'PRESERVE_DATA',
                'DELETE_DATA'
            ],
            description: 'Select MSSQL cleanup mode'
        )
    }

    stages {

        stage('Validate Cleanup Parameters') {
            steps {
                script {

                    if (
                        params.CLEANUP_MODE != 'PRESERVE_DATA' &&
                        params.CLEANUP_MODE != 'DELETE_DATA'
                    ) {
                        error("Invalid CLEANUP_MODE: ${params.CLEANUP_MODE}")
                    }

                    echo "====================================="
                    echo "MSSQL CLEANUP PARAMETERS"
                    echo "====================================="
                    echo "Cleanup Mode : ${params.CLEANUP_MODE}"
                }
            }
        }

        stage('Run MSSQL Cleanup') {
            steps {

                withEnv([
                    "CLEANUP_MODE=${params.CLEANUP_MODE}"
                ]) {

                    bat '''
                    @echo off

                    echo.
                    echo =====================================
                    echo RUNNING MSSQL CLEANUP
                    echo =====================================
                    echo.

                    call "%WORKSPACE%\\scripts\\batch\\mssql\\cleanup\\mssql_cleanup_pipeline.bat"

                    if errorlevel 1 (
                        echo.
                        echo MSSQL CLEANUP FAILED
                        exit /b 1
                    )

                    echo.
                    echo MSSQL CLEANUP COMPLETED SUCCESSFULLY
                    '''
                }
            }
        }
    }

    post {

        success {
            echo 'MSSQL CLEANUP SUCCESSFUL'
        }

        failure {
            echo 'MSSQL CLEANUP FAILED'
        }

        always {
            echo 'MSSQL CLEANUP PIPELINE COMPLETED'
        }
    }
}