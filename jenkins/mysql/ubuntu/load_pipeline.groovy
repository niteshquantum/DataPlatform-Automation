def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mysql \
        --action load \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mysql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mysql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mysql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --failed-stage "${stageName}" \
            --message "Stage execution failed"
        """

        throw error
    }
}


pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {

        stage('Initialize Logging') {

            steps {

                sh """
                    python3 scripts/logging/logger.py init \
                    --database mysql \
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


        stage('Validate Python Runtime') {

            steps {

                script {

                    runTrackedStage('Validate Python Runtime') {

                        sh './scripts/bash/common/validate_python_runtime.sh'
                    }
                }
            }
        }


        stage('Validate Python Requirements') {

            steps {

                script {

                    runTrackedStage('Validate Python Requirements') {

                        sh './scripts/bash/mysql/setup/validate_python_requirements.sh'
                    }
                }
            }
        }


        stage('Start MySQL') {

            steps {

                script {

                    runTrackedStage('Start MySQL') {

                        sh './scripts/bash/mysql/setup/start_mysql.sh'
                    }
                }
            }
        }


        stage('Validate MySQL') {

            steps {

                script {

                    runTrackedStage('Validate MySQL') {

                        sh './scripts/bash/mysql/setup/validate_mysql.sh'
                    }
                }
            }
        }


        stage('Download Dataset') {

            steps {

                script {

                    runTrackedStage('Download Dataset') {

                        sh './scripts/bash/common/download_dataset.sh'
                    }
                }
            }
        }


        stage('Load Data') {

            steps {

                script {

                    runTrackedStage('Load Data') {

                        sh './scripts/bash/mysql/load/load_data.sh'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {

            steps {

                script {

                    runTrackedStage('Validate Loaded Data') {

                        sh './scripts/bash/mysql/load/validate_loaded_data.sh'
                    }
                }
            }
        }

        stage('Deploy Views') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Views') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Functions') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Functions') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Deploy Triggers') {
            steps {
                sh './scripts/bash/mysql/objects/deploy_objects.sh'
            }
        }

        stage('Validate Triggers') {
            steps {
                sh './scripts/bash/mysql/objects/validate_objects.sh'
            }
        }

        stage('Assessment Inventories') {
            steps {
                sh './scripts/bash/mysql/assessment/run_assessment.sh all'
            }
        }

        stage('Final Assessment Report') {
            steps {
                sh './scripts/bash/common/generate_assessment_report.sh'
            }
        }
    }


    post {

        success {

            echo 'UBUNTU MYSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU MYSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU MYSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database mysql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database mysql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database mysql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/load/build_${env.BUILD_NUMBER}/**, reports/mysql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, outputs/assessments/mysql/**, outputs/assessments/assessment_report.json",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
