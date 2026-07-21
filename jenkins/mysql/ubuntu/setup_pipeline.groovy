def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mysql \
        --action setup \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mysql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mysql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mysql \
            --action setup \
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

        stage('Set Permissions') {

            steps {

                sh '''
                    find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                '''
            }
        }


        stage('Initialize Logging') {

            steps {

                sh """
                    python3 scripts/logging/logger.py init \
                    --database mysql \
                    --action setup \
                    --os ubuntu \
                    --build-number "${env.BUILD_NUMBER}" \
                    --job-name "${env.JOB_NAME}" \
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('MySQL Setup') {

            steps {

                script {

                    runTrackedStage(
                        'MySQL Setup'
                    ) {

                        sh 'bash scripts/bash/mysql/mysql_setup_pipeline.sh'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'UBUNTU MYSQL SETUP SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU MYSQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU MYSQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database mysql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database mysql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database mysql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}
