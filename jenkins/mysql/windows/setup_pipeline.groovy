def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mysql ^
        --action setup ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action setup ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mysql ^
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
                    --database mysql ^
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
                            echo 'MySQL Service and Global MySQL configuration will be enabled.'

                        } else {

                            writeFile(
                                file: 'admin_status.txt',
                                text: 'false'
                            )

                            echo 'Administrator privileges not available.'
                            echo 'MySQL Service and Global MySQL configuration will be skipped.'
                            echo 'MySQL will run using project-local mode.'
                        }

                        def adminResult = readFile(
                            'admin_status.txt'
                        ).trim()

                        echo "ADMIN STATUS = ${adminResult}"

                        bat """
                            python scripts\\logging\\logger.py set-environment ^
                            --database mysql ^
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

                        bat 'scripts\\batch\\mysql\\setup\\install_python_requirements.bat'
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

                        bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
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

                        bat 'scripts\\batch\\mysql\\setup\\install_tools.bat'
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

                        bat 'scripts\\batch\\mysql\\setup\\deploy_mysql.bat'
                    }
                }
            }
        }


        stage('Configure MySQL Service') {

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
                        'Configure MySQL Service'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring MySQL Windows Service...'

                        bat 'scripts\\batch\\mysql\\setup\\configure_mysql_service.bat'
                    }
                }
            }
        }


        stage('Start MySQL') {

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
                        'Start MySQL'
                    ) {

                        echo 'Administrator privileges unavailable.'
                        echo 'Starting MySQL in project-local mode...'

                        bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
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

                        bat 'scripts\\batch\\mysql\\setup\\create_database.bat'
                    }
                }
            }
        }

<<<<<<< HEAD
        stage('Deploy Views') {
            steps {
                script {
                    def viewsStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\views\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (viewsStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Validate Views') {
            steps {
                script {
                    def viewsStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\views\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (viewsStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Deploy Functions') {
            steps {
                script {
                    def functionsStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\functions\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (functionsStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Validate Functions') {
            steps {
                script {
                    def functionsStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\functions\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (functionsStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                script {
                    def proceduresStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\procedures\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (proceduresStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                script {
                    def proceduresStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\procedures\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (proceduresStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Deploy Triggers') {
            steps {
                script {
                    def triggersStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\triggers\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (triggersStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }

        stage('Validate Triggers') {
            steps {
                script {
                    def triggersStatus = bat(
                        script: 'if exist liquibase\\mysql\\objects\\triggers\\*.xml (exit /b 0) else (exit /b 1)',
                        returnStatus: true
                    )
                    if (triggersStatus == 0) {
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }
=======
>>>>>>> main

        stage('Configure Global MySQL') {

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
                        'Configure Global MySQL'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring Global MySQL command...'

                        bat 'scripts\\batch\\mysql\\setup\\configure_global_mysql.bat'
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

                        bat 'scripts\\batch\\mysql\\setup\\validate_environment.bat'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MYSQL SETUP SUCCESSFUL'

            script {

                def adminResult = readFile(
                    'admin_status.txt'
                ).trim()

                if (adminResult == 'true') {

                    echo 'MySQL Windows Service configured successfully.'
                    echo 'Global MySQL configuration completed successfully.'

                } else {

                    echo 'MySQL configured successfully in project-local mode.'
                    echo 'Windows Service and Global MySQL configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }


        failure {

            echo 'MYSQL SETUP FAILED'
        }


        always {

            echo 'FINALIZING MYSQL SETUP LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mysql ^
                    --action setup ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


                archiveArtifacts(
                    artifacts: "logs/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/mysql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**",
                    fingerprint: true,
                    allowEmptyArchive: true
                )

            echo 'MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}