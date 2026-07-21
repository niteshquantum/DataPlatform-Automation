def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mssql \
        --action load \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mssql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --failed-stage "${stageName}" \
            --message "Stage execution failed"
        """

        throw error
    }
}


pipeline {

    agent {
        label 'ubuntu-node'
    }

    options {
        disableConcurrentBuilds()
    }


    stages {

        stage('Initialize Logging') {

            steps {

                sh """
                    python3 scripts/logging/logger.py init \
                    --database mssql \
                    --action load \
                    --os ubuntu \
                    --build-number "${env.BUILD_NUMBER}" \
                    --job-name "${env.JOB_NAME}" \
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('Set Permissions') {

            steps {

                script {

                    runTrackedStage('Set Permissions') {

                        sh '''
                            find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                        '''
                    }
                }
            }
        }


        stage('MSSQL Load') {

            steps {

                script {

                    runTrackedStage('MSSQL Load') {

                        sh 'bash scripts/bash/mssql/mssql_load_pipeline.sh'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'UBUNTU MSSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU MSSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU MSSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mssql/load/build_${env.BUILD_NUMBER}/**, reports/mssql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mssql/**, outputs/assessments/mssql/**, outputs/assessments/assessment_report.json, metadata/profiling/mssql/**, metadata/reconciliation/mssql/**, metadata/discovery/mssql/**, metadata/assessment/mssql/**, metadata/recommendation/mssql/**, metadata/governance/mssql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}
