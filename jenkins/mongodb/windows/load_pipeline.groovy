def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mongodb ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mongodb ^
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
                    --database mongodb ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MongoDB Load') {

            steps {

                script {

                    runTrackedStage(
                        'MongoDB Load'
                    ) {

                        bat 'scripts\\batch\\mongodb\\mongodb_load_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MONGODB LOAD SUCCESSFUL'
        }


        failure {

            echo 'MONGODB LOAD FAILED'
        }


        always {

            echo 'FINALIZING MONGODB LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mongodb/**, outputs/assessments/mongodb/**, outputs/assessments/assessment_report.json, metadata/profiling/mongodb/**, metadata/reconciliation/mongodb/**, metadata/discovery/mongodb/**, metadata/assessment/mongodb/**, metadata/recommendation/mongodb/**, metadata/governance/mongodb/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MONGODB LOAD PIPELINE COMPLETED'
        }
    }
}
