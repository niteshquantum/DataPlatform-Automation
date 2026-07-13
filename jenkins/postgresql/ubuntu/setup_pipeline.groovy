def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database postgresql \
        --action setup \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database postgresql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database postgresql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database postgresql \
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

        stage('Initialize Logging') {

            steps {

                sh """
                    python3 scripts/logging/logger.py init \
                    --database postgresql \
                    --action setup \
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


        stage('Install Python Requirements') {

            steps {

                script {

                    runTrackedStage('Install Python Requirements') {

                        sh './scripts/bash/postgresql/setup/install_python_requirements.sh'
                    }
                }
            }
        }


        stage('Validate Python Requirements') {

            steps {

                script {

                    runTrackedStage('Validate Python Requirements') {

                        sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
                    }
                }
            }
        }


        stage('Validate Java Runtime') {

            steps {

                script {

                    runTrackedStage('Validate Java Runtime') {

                        sh './scripts/bash/common/validate_java_runtime.sh'
                    }
                }
            }
        }


        stage('Install Tools') {

            steps {

                script {

                    runTrackedStage('Install Tools') {

                        sh './scripts/bash/postgresql/setup/install_tools.sh'
                    }
                }
            }
        }


        stage('Deploy PostgreSQL') {

            steps {

                script {

                    runTrackedStage('Deploy PostgreSQL') {

                        sh './scripts/bash/postgresql/setup/deploy_postgresql.sh'
                    }
                }
            }
        }


        stage('Install PostgreSQL') {

            steps {

                script {

                    runTrackedStage('Install PostgreSQL') {

                        sh './scripts/bash/postgresql/setup/install_postgresql.sh'
                    }
                }
            }
        }


        stage('Start PostgreSQL') {

            steps {

                script {

                    runTrackedStage('Start PostgreSQL') {

                        sh './scripts/bash/postgresql/setup/start_postgresql.sh'
                    }
                }
            }
        }


        stage('Configure PostgreSQL User') {

            steps {

                script {

                    runTrackedStage('Configure PostgreSQL User') {

                        sh './scripts/bash/postgresql/setup/configure_postgresql.sh'
                    }
                }
            }
        }

<<<<<<< HEAD
        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/postgresql/setup/run_liquibase.sh'
            }
        }

=======

        stage('Create Database') {

            steps {

                script {

                    runTrackedStage('Create Database') {

                        sh './scripts/bash/postgresql/setup/create_database.sh'
                    }
                }
            }
        }


>>>>>>> main
        stage('Configure Global PSQL') {

            steps {

                script {

                    runTrackedStage('Configure Global PSQL') {

                        sh './scripts/bash/postgresql/setup/configure_global_psql.sh'
                    }
                }
            }
        }


        stage('Validate PostgreSQL') {

            steps {

                script {

                    runTrackedStage('Validate PostgreSQL') {

                        sh './scripts/bash/postgresql/setup/validate_postgresql.sh'
                    }
                }
            }
        }


        stage('Validate Environment') {

            steps {

                script {

                    runTrackedStage('Validate Environment') {

                        sh './scripts/bash/postgresql/setup/validate_environment.sh'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'UBUNTU POSTGRESQL SETUP SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU POSTGRESQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU POSTGRESQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database postgresql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database postgresql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database postgresql \
                    --action setup \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}