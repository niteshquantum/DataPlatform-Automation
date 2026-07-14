def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mysql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mysql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mysql ^
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
                    --database mysql ^
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

                        bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start MySQL Service') {

            steps {

                script {

                    runTrackedStage(
                        'Start MySQL Service'
                    ) {

                        bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
                    }
                }
            }
        }


        stage('Validate MySQL') {

            steps {

                script {

                    runTrackedStage(
                        'Validate MySQL'
                    ) {

                        bat 'scripts\\batch\\mysql\\setup\\validate_mysql.bat'
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

                        bat 'scripts\\batch\\common\\migration\\run_data_profiling.bat mysql'
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

                        bat 'scripts\\batch\\mysql\\load\\load_data.bat'
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

                        bat 'scripts\\batch\\mysql\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }


        stage('Deploy Views') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Views') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Functions') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Functions') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Stored Procedures') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Stored Procedures') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Triggers') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Triggers') {

            steps {

                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }


        stage('Database Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat database'
            }
        }


        stage('Schema Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat schema'
            }
        }


        stage('Table Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat table'
            }
        }


        stage('View Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat view'
            }
        }


        stage('Stored Procedure Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat procedure'
            }
        }


        stage('Function Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat function'
            }
        }


        stage('Trigger Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat trigger'
            }
        }


        stage('Event Inventory') {

            steps {

                bat 'scripts\\batch\\mysql\\assessment\\run_assessment.bat event'
            }
        }


        stage('Assessment Report') {

            steps {

                bat 'scripts\\batch\\common\\generate_assessment_report.bat'
            }
        }


        stage('Reconcile Source and Target Data') {

            steps {

                script {

                    runTrackedStage(
                        'Reconcile Source and Target Data'
                    ) {

                        bat 'scripts\\batch\\common\\migration\\run_reconciliation.bat mysql'
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

                        bat 'python scripts\\discovery\\discovery_engine.py --database mysql'
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

                        bat 'python scripts\\discovery\\growth_analyzer.py --database mysql'
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

                        bat 'python scripts\\discovery\\requirement_analyzer.py --database mysql'
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

                        bat 'scripts\\batch\\common\\migration\\run_assessment.bat mysql'
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

                        bat 'scripts\\batch\\common\\migration\\run_recommendation.bat mysql'
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

                        bat 'scripts\\batch\\common\\migration\\run_action_plan.bat mysql'
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

                        bat 'scripts\\batch\\common\\migration\\generate_technical_report.bat mysql'
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

                        bat 'scripts\\batch\\common\\migration\\generate_executive_report.bat mysql'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'MYSQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'MYSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING MYSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mysql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mysql/load/build_${env.BUILD_NUMBER}/**, reports/mysql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mysql/**, outputs/assessments/mysql/**, outputs/assessments/assessment_report.json, metadata/profiling/mysql/**, metadata/reconciliation/mysql/**, metadata/discovery/mysql/**, metadata/assessment/mysql/**, metadata/recommendation/mysql/**, metadata/governance/mysql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}