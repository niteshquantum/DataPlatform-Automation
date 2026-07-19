def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mongodb ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mongodb ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mongodb ^
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
                    --database mongodb ^
                    --action load ^
                    --os windows ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --job-name "${env.JOB_NAME}" ^
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

                        bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start MongoDB Service') {

            steps {

                script {

                    runTrackedStage(
                        'Start MongoDB Service'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\start_mongodb.bat'
                    }
                }
            }
        }


        stage('Validate MongoDB') {

            steps {

                script {

                    runTrackedStage(
                        'Validate MongoDB'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
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

                        bat 'scripts\\batch\\common\\migration\\run_data_profiling.bat mongodb'
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

                        bat 'scripts\\batch\\mongodb\\load\\load_data.bat'
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

                        bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
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

                        bat 'scripts\\batch\\mongodb\\assessment\\run_assessment.bat all'
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

                        bat 'scripts\\batch\\common\\migration\\run_reconciliation.bat mongodb'
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

                        bat 'python scripts\\discovery\\discovery_engine.py --database mongodb'
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

                        bat 'python scripts\\discovery\\growth_analyzer.py --database mongodb'
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

                        bat 'python scripts\\discovery\\requirement_analyzer.py --database mongodb'
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

                        bat 'scripts\\batch\\common\\migration\\run_assessment.bat mongodb'
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

                        bat 'scripts\\batch\\common\\migration\\run_recommendation.bat mongodb'
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

                        bat 'scripts\\batch\\common\\migration\\run_action_plan.bat mongodb'
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

                        bat 'scripts\\batch\\common\\migration\\generate_technical_report.bat mongodb'
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

                        bat 'scripts\\batch\\common\\migration\\generate_executive_report.bat mongodb'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MONGODB LOAD SUCCESSFUL'
        }


        failure {

            echo 'MONGODB LOAD FAILED'
        }


        always {

            echo 'FINALIZING MONGODB LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mongodb ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/mongodb/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mongodb/**, outputs/assessments/mongodb/**, outputs/assessments/assessment_report.json, metadata/profiling/mongodb/**, metadata/reconciliation/mongodb/**, metadata/discovery/mongodb/**, metadata/assessment/mongodb/**, metadata/recommendation/mongodb/**, metadata/governance/mongodb/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MONGODB LOAD PIPELINE COMPLETED'
        }
    }
}