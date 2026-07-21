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

                    runTrackedStage(
                        'Run CDC'
                    ) {

                        bat 'scripts\\batch\\postgresql\\load\\run_cdc.bat'
                    }
                }
            }
        }


        stage('Load Data') {

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


        /*
        ============================================================
        OPTIONAL POST-PROCESSING
        Assessment/reporting is intentionally not part of CORE LOAD.
        Execute through dedicated assessment/reporting entry point.
        ============================================================
        */


        stage('Database Assessment') {

            when {

                expression {
                    return params.RUN_ASSESSMENT == 'true'
                }
            }

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

            when {

                expression {
                    return params.RUN_ASSESSMENT == 'true'
                }
            }

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
