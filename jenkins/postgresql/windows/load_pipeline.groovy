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
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
                    --build-url "${env.BUILD_URL}"
                """
                env.POSTGRESQL_LOAD_LOGGING_INITIALIZED = 'true'
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


        stage('Start PostgreSQL') {

            steps {

                script {

                    runTrackedStage(
                        'Start PostgreSQL'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
                    }
                }
            }
        }


        stage('Validate PostgreSQL Instance') {

            steps {

                script {

                    runTrackedStage(
                        'Validate PostgreSQL Instance'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\validate_postgresql.bat'
                    }
                }
            }
        }


        stage('Download Dataset') {

            steps {

                script {

                    runTrackedStage(
                        'Download Dataset'
                    ) {

                        bat 'scripts\\batch\\common\\download_dataset.bat'
                    }
                }
            }
        }


        stage('Profile Source Data') {

            steps {

                script {

                    runTrackedStage(
                        'Profile Source Data'
                    ) {

                        bat 'python scripts\\profiling\\data_profiler.py --database postgresql'
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


        stage('Run CDC') {

            steps {

                script {

                    bat """
                        python scripts\\logging\\logger.py stage-start ^
                        --database postgresql ^
                        --action load ^
                        --build-number "${env.BUILD_NUMBER}" ^
                        --stage-name "Run CDC"
                    """

                    def cdcResult = bat(
                        script: 'scripts\\batch\\postgresql\\load\\run_cdc.bat',
                        returnStatus: true
                    )

                    if (cdcResult == 0 || cdcResult == 100) {
                        bat """
                            python scripts\\logging\\logger.py stage-end ^
                            --database postgresql ^
                            --action load ^
                            --build-number "${env.BUILD_NUMBER}" ^
                            --stage-name "Run CDC" ^
                            --status SUCCESS
                        """
                        if (cdcResult == 100) {
                            env.SKIP_DATA_LOAD = 'true'
                        }
                    } else {
                        bat """
                            python scripts\\logging\\logger.py stage-end ^
                            --database postgresql ^
                            --action load ^
                            --build-number "${env.BUILD_NUMBER}" ^
                            --stage-name "Run CDC" ^
                            --status FAILURE
                        """
                        bat """
                            python scripts\\logging\\logger.py set-error ^
                            --database postgresql ^
                            --action load ^
                            --build-number "${env.BUILD_NUMBER}" ^
                            --failed-stage "Run CDC" ^
                            --message "CDC execution failed with exit code ${cdcResult}"
                        """
                        error "CDC execution failed with exit code ${cdcResult}"
                    }
                }
            }
        }


        stage('Load Data') {

            when {
                expression {
                    return env.SKIP_DATA_LOAD != 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Load Data'
                    ) {

                        bat 'scripts\\batch\\postgresql\\load\\load_data.bat'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {

            when {
                expression {
                    return env.SKIP_DATA_LOAD != 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Validate Loaded Data'
                    ) {

                        bat 'scripts\\batch\\postgresql\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }


        stage('Deploy Database Objects') {

            steps {

                script {

                    runTrackedStage(
                        'Deploy Database Objects'
                    ) {

                        bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
                    }
                }
            }
        }


        stage('Validate Database Objects') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Database Objects'
                    ) {

                        bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
                    }
                }
            }
        }


        stage('Database Assessment') {

            steps {

                script {

                    runTrackedStage(
                        'Database Assessment'
                    ) {

                        bat 'scripts\\batch\\postgresql\\assessment\\run_assessment.bat all'
                    }
                }
            }
        }


        stage('Assessment Report') {

            steps {

                script {

                    runTrackedStage(
                        'Assessment Report'
                    ) {

                        bat 'scripts\\batch\\common\\generate_assessment_report.bat'
                    }
                }
            }
        }


        stage('Reconcile Source and Target Data') {

            steps {

                script {

                    runTrackedStage(
                        'Reconcile Source and Target Data'
                    ) {

                        bat 'python scripts\\reconciliation\\reconciliation_engine.py --database postgresql'
                    }
                }
            }
        }


        stage('Discover Database Environment') {

            steps {

                script {

                    runTrackedStage(
                        'Discover Database Environment'
                    ) {

                        bat 'python scripts\\discovery\\discovery_engine.py --database postgresql'
                    }
                }
            }
        }


        stage('Analyze Database Growth') {

            steps {

                script {

                    runTrackedStage(
                        'Analyze Database Growth'
                    ) {

                        bat 'python scripts\\discovery\\growth_analyzer.py --database postgresql'
                    }
                }
            }
        }


        stage('Analyze Migration Requirements') {

            steps {

                script {

                    runTrackedStage(
                        'Analyze Migration Requirements'
                    ) {

                        bat 'python scripts\\discovery\\requirement_analyzer.py --database postgresql'
                    }
                }
            }
        }


        stage('Assess Migration') {

            steps {

                script {

                    runTrackedStage(
                        'Assess Migration'
                    ) {

                        bat 'python scripts\\assessment\\assessment_engine.py --database postgresql'
                    }
                }
            }
        }


        stage('Generate Migration Recommendations') {

            steps {

                script {

                    runTrackedStage(
                        'Generate Migration Recommendations'
                    ) {

                        bat 'python scripts\\recommendation\\recommendation_engine.py --database postgresql'
                    }
                }
            }
        }


        stage('Generate Governance Action Plan') {

            steps {

                script {

                    runTrackedStage(
                        'Generate Governance Action Plan'
                    ) {

                        bat 'python scripts\\governance\\action_plan_engine.py --database postgresql'
                    }
                }
            }
        }


        stage('Generate Technical Migration Report') {

            steps {

                script {

                    runTrackedStage(
                        'Generate Technical Migration Report'
                    ) {

                        bat 'python scripts\\reporting\\migration\\technical_report.py --database postgresql'
                    }
                }
            }
        }


        stage('Generate Executive Migration Report') {

            steps {

                script {

                    runTrackedStage(
                        'Generate Executive Migration Report'
                    ) {

                        bat 'python scripts\\reporting\\migration\\executive_report.py --database postgresql'
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

                def finalStatus = currentBuild.currentResult ?: 'FAILURE'

                if (env.POSTGRESQL_LOAD_LOGGING_INITIALIZED == 'true') {

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

                } else {

                    echo 'SKIPPING FINALIZE/REPORT: logging was not initialized'
                }
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