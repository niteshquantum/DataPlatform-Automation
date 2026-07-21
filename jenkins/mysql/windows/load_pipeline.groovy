def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mysql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mysql ^
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
                    --database mysql ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MySQL Load') {

            steps {

                script {

                    runTrackedStage(
                        'MySQL Load'
                    ) {

                        bat 'scripts\\batch\\mysql\\mysql_load_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MYSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'MYSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING MYSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/load/build_${env.BUILD_NUMBER}/**, reports/mysql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mysql/**, outputs/assessments/mysql/**, outputs/assessments/assessment_report.json, metadata/profiling/mysql/**, metadata/reconciliation/mysql/**, metadata/discovery/mysql/**, metadata/assessment/mysql/**, metadata/recommendation/mysql/**, metadata/governance/mysql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
