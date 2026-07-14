def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mssql \
        --action setup \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mssql \
            --action setup \
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
                    --database mssql \
                    --action setup \
                    --os ubuntu \
                    --build-number "${env.BUILD_NUMBER}" \
                    --job-name "${env.JOB_NAME}" \
                    --build-url "${env.BUILD_URL}"
                """
            }
        }

                stage('Validate Python Runtime') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Python Runtime'
                    ) {

                        sh './scripts/bash/common/validate_python_runtime.sh'
                    }
                }
            }
        }


        stage('Install Python Requirements') {

            steps {

                script {

                    runTrackedStage(
                        'Install Python Requirements'
                    ) {

                        sh './scripts/bash/mssql/setup/install_python_requirements.sh'
                    }
                }
            }
        }


        stage('Validate Python Requirements') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Python Requirements'
                    ) {

                        sh './scripts/bash/mssql/setup/validate_python_requirements.sh'
                    }
                }
            }
        }


        stage('Validate Java Runtime') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Java Runtime'
                    ) {

                        sh './scripts/bash/common/validate_java_runtime.sh'
                    }
                }
            }
        }


        stage('Install Tools') {

            steps {

                script {

                    runTrackedStage(
                        'Install Tools'
                    ) {

                        sh './scripts/bash/mssql/setup/install_tools.sh'
                    }
                }
            }
        }


        stage('Deploy MSSQL') {

            steps {

                script {

                    runTrackedStage(
                        'Deploy MSSQL'
                    ) {

                        sh './scripts/bash/mssql/setup/deploy_mssql.sh'
                    }
                }
            }
        }

        stage('Configure MSSQL') {
            steps {
                script {
                    runTrackedStage('Configure MSSQL') {
                        sh './scripts/bash/mssql/setup/configure_mssql.sh'
                    }
                }
            }
        }

                stage('Start MSSQL') {

            steps {

                script {

                    runTrackedStage(
                        'Start MSSQL'
                    ) {

                        sh './scripts/bash/mssql/setup/start_mssql.sh'
                    }
                }
            }
        }


        stage('Create Database') {

            steps {

                script {

                    runTrackedStage(
                        'Create Database'
                    ) {

                        sh './scripts/bash/mssql/setup/create_database.sh'
                    }
                }
            }
        }

        stage('Run Liquibase') {
            steps {
                script {
                    runTrackedStage('Run Liquibase') {
                        sh './scripts/bash/mssql/setup/run_liquibase.sh'
                    }
                }
            }
        }


        stage('Validate Environment') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Environment'
                    ) {

                        sh './scripts/bash/mssql/setup/validate_environment.sh'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'UBUNTU MSSQL SETUP SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU MSSQL SETUP FAILED'
        }

                always {

            echo 'FINALIZING UBUNTU MSSQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database mssql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database mssql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database mssql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }

            archiveArtifacts(
                artifacts: "logs/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MSSQL SETUP PIPELINE COMPLETED'
        }
    }
}

