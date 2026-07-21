def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mssql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mssql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mssql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mssql ^
            --action load ^
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
                    --database mssql ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MSSQL Load') {

            steps {

                script {

                    runTrackedStage(
                        'MSSQL Load'
                    ) {

                        bat 'scripts\\batch\\mssql\\mssql_load_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MSSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'MSSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING MSSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mssql/load/build_${env.BUILD_NUMBER}/**, reports/mssql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mssql/**, outputs/assessments/mssql/**, outputs/assessments/assessment_report.json, metadata/profiling/mssql/**, metadata/reconciliation/mssql/**, metadata/discovery/mssql/**, metadata/assessment/mssql/**, metadata/recommendation/mssql/**, metadata/governance/mssql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}
