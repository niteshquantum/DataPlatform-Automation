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
                    --database mysql \
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

                        sh './scripts/bash/mysql/setup/install_python_requirements.sh'
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

                        sh './scripts/bash/mysql/setup/validate_python_requirements.sh'
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

                        sh './scripts/bash/mysql/setup/install_tools.sh'
                    }
                }
            }
        }


        stage('Install MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Install MySQL'
                    ) {

                        sh './scripts/bash/mysql/setup/install_mysql.sh'
                    }
                }
            }
        }


        stage('Deploy MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Deploy MySQL'
                    ) {

                        sh './scripts/bash/mysql/setup/deploy_mysql.sh'
                    }
                }
            }
        }


        stage('Start MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Start MySQL'
                    ) {

                        sh './scripts/bash/mysql/setup/start_mysql.sh'
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

                        sh './scripts/bash/mysql/setup/create_database.sh'
                    }
                }
            }
        }

<<<<<<< HEAD
        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/mysql/setup/run_liquibase.sh'
            }
        }
=======
>>>>>>> main

        stage('Configure Global MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Configure Global MySQL'
                    ) {

                        sh 'bash ./scripts/bash/mysql/setup/configure_global_mysql.sh'
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

                        sh './scripts/bash/mysql/setup/validate_environment.sh'
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