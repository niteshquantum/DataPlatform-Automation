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
                    --database mssql ^
                    --action setup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MSSQL Setup') {

            steps {

                bat 'scripts\\batch\\mssql\\mssql_setup_pipeline.bat'
            }
        }
    }


    post {

        success {

            echo 'MSSQL SETUP SUCCESSFUL'

            script {

                def adminResult = bat(
                    script: 'python scripts\\logging\\logger.py get-environment ^
                        --database mssql ^
                        --action setup ^
                        --build-number "${env.BUILD_NUMBER}" ^
                        --administrator-privileges',
                    returnStdout: true
                ).trim()

                if (adminResult == 'true') {

                    echo 'SQL Server network configuration completed successfully.'

                } else {

                    echo 'Administrator privileges were unavailable.'
                    echo 'SQL Server network configuration was skipped.'
                }
            }
        }


        failure {

            echo 'MSSQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING MSSQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mssql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mssql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mssql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MSSQL SETUP PIPELINE COMPLETED'
        }
    }
}
