def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database postgresql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database postgresql ^
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
                    --database postgresql ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('PostgreSQL Load') {

            steps {

                script {

                    runTrackedStage(
                        'PostgreSQL Load'
                    ) {

                        bat 'scripts\\batch\\postgresql\\postgresql_load_pipeline.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'POSTGRESQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'POSTGRESQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING POSTGRESQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database postgresql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/postgresql/**, outputs/assessments/postgresql/**, outputs/assessments/assessment_report.json, metadata/profiling/postgresql/**, metadata/reconciliation/postgresql/**, metadata/discovery/postgresql/**, metadata/assessment/postgresql/**, metadata/recommendation/postgresql/**, metadata/governance/postgresql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}
