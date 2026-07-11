def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database postgresql ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database postgresql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database postgresql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --failed-stage "${stageName}" ^
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

                bat """
                    python scripts\\logging\\logger.py init ^
                    --database postgresql ^
                    --action setup ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
            }
        }


        stage('Check Administrator Privileges') {

            steps {

                script {

                    runTrackedStage(
                        'Check Administrator Privileges'
                    ) {

                        def adminStatus = bat(
                            script: 'scripts\\batch\\common\\check_admin_privileges.bat',
                            returnStatus: true
                        )

                        if (adminStatus == 0) {

                            writeFile(
                                file: 'admin_status.txt',
                                text: 'true'
                            )

                            echo 'Administrator privileges available.'
                            echo 'Windows Service and Global PSQL configuration will be enabled.'

                        } else {

                            writeFile(
                                file: 'admin_status.txt',
                                text: 'false'
                            )

                            echo 'Administrator privileges not available.'
                            echo 'Windows Service and Global PSQL configuration will be skipped.'
                            echo 'PostgreSQL will run using project-local configuration.'
                        }

                        def adminResult = readFile(
                            'admin_status.txt'
                        ).trim()

                        echo "ADMIN STATUS = ${adminResult}"

                        bat """
                            python scripts\\logging\\logger.py set-environment ^
                            --database postgresql ^
                            --action setup ^
                            --build-number "${env.BUILD_NUMBER}" ^
                            --administrator-privileges "${adminResult}"
                        """
                    }
                }
            }
        }


        stage('Validate Python Runtime') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Python Runtime'
                    ) {

                        bat 'scripts\\batch\\common\\validate_python_runtime.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\install_python_requirements.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
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

                        bat 'scripts\\batch\\common\\validate_java_runtime.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\install_tools.bat'
                    }
                }
            }
        }


        stage('Deploy PostgreSQL') {

            steps {

                script {

                    runTrackedStage(
                        'Deploy PostgreSQL'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\deploy_postgresql.bat'
                    }
                }
            }
        }


        stage('Configure PostgreSQL Service') {

            when {

                expression {

                    return readFile(
                        'admin_status.txt'
                    ).trim() == 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Configure PostgreSQL Service'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring PostgreSQL Windows Service...'

                        bat 'scripts\\batch\\postgresql\\setup\\configure_postgresql_service.bat'
                    }
                }
            }
        }


        stage('Start PostgreSQL') {

            when {

                expression {

                    return readFile(
                        'admin_status.txt'
                    ).trim() != 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Start PostgreSQL'
                    ) {

                        echo 'Administrator privileges unavailable.'
                        echo 'Starting PostgreSQL in project-local mode...'

                        bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\create_database.bat'
                    }
                }
            }
        }


        stage('Configure Global PSQL') {

            when {

                expression {

                    return readFile(
                        'admin_status.txt'
                    ).trim() == 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Configure Global PSQL'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring Global PSQL command...'

                        bat 'scripts\\batch\\postgresql\\setup\\configure_global_psql.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\validate_environment.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'POSTGRESQL SETUP SUCCESSFUL'

            script {

                def adminResult = readFile(
                    'admin_status.txt'
                ).trim()

                if (adminResult == 'true') {

                    echo 'PostgreSQL Windows Service configured successfully.'
                    echo 'Global PSQL configuration completed successfully.'

                } else {

                    echo 'PostgreSQL configured successfully in project-local mode.'
                    echo 'Windows Service and Global PSQL configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }


        failure {

            echo 'POSTGRESQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING POSTGRESQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database postgresql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }

            archiveArtifacts(
                artifacts: "logs/postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/postgresql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}