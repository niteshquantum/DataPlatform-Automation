def runTrackedStage(String stageName, Closure stageBody) {

    bat """
        python scripts\\logging\\logger.py stage-start ^
        --database mssql ^
        --action load ^
        --build-number "${env.BUILD_NUMBER}" ^
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mssql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status SUCCESS
        """

    } catch (Exception error) {

        bat """
            python scripts\\logging\\logger.py stage-end ^
            --database mssql ^
            --action load ^
            --build-number "${env.BUILD_NUMBER}" ^
            --stage-name "${stageName}" ^
            --status FAILURE
        """

        bat """
            python scripts\\logging\\logger.py set-error ^
            --database mssql ^
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
                    --database mssql ^
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
                    runTrackedStage('Validate Python Runtime') {
                        bat 'scripts\\batch\\common\\validate_python_runtime.bat'
                    }
                }
            }
        }


        stage('Validate Python Requirements') {
            steps {
                script {
                    runTrackedStage('Validate Python Requirements') {
                        bat 'scripts\\batch\\mssql\\setup\\validate_python_requirements.bat'
                    }
                }
            }
        }


        stage('Start SQL Server') {
            steps {
                script {
                    runTrackedStage('Start SQL Server') {
                        bat 'scripts\\batch\\mssql\\setup\\start_mssql.bat'
                    }
                }
            }
        }


        stage('Validate SQL Server') {
            steps {
                script {
                    runTrackedStage('Validate SQL Server') {
                        bat 'scripts\\batch\\mssql\\setup\\validate_mssql.bat'
                    }
                }
            }
        }


        stage('Download Dataset') {
            steps {
                script {
                    runTrackedStage('Download Dataset') {
                        bat 'scripts\\batch\\common\\download_dataset.bat'
                    }
                }
            }
        }


        stage('Profile Source Data') {
            steps {
                script {
                    runTrackedStage('Profile Source Data') {
                        bat 'scripts\\batch\\common\\migration\\run_data_profiling.bat mssql'
                    }
                }
            }
        }


        stage('Load Data') {
            steps {
                script {
                    runTrackedStage('Load Data') {
                        bat 'scripts\\batch\\mssql\\load\\load_data.bat'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {
            steps {
                script {
                    runTrackedStage('Validate Loaded Data') {
                        bat 'scripts\\batch\\mssql\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }


        stage('Deploy Views') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Views') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Functions') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Functions') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat'
            }
        }


        stage('Deploy Triggers') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat'
            }
        }


        stage('Validate Triggers') {
            steps {
                bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat'
            }
        }


        stage('Database Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat database'
            }
        }


        stage('Schema Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat schema'
            }
        }


        stage('Table Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat table'
            }
        }


        stage('View Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat view'
            }
        }


        stage('Stored Procedure Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat procedure'
            }
        }


        stage('Function Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat function'
            }
        }


        stage('Trigger Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat trigger'
            }
        }


        stage('SQL Agent Inventory') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat sql_agent_inventory'
            }
        }


        stage('SQL Agent Validation') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat sql_agent_validation'
            }
        }


        stage('SQL Agent History') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat sql_agent_history'
            }
        }


        stage('SQL Agent Assessment') {
            steps {
                bat 'scripts\\batch\\mssql\\assessment\\run_assessment.bat sql_agent_assessment'
            }
        }


        stage('Final Assessment Report') {
            steps {
                bat 'scripts\\batch\\common\\generate_assessment_report.bat'
            }
        }


        stage('Reconcile Source and Target Data') {
            steps {
                script {
                    runTrackedStage('Reconcile Source and Target Data') {
                        bat 'scripts\\batch\\common\\migration\\run_reconciliation.bat mssql'
                    }
                }
            }
        }


        stage('Discover Database Environment') {
            steps {
                script {
                    runTrackedStage('Discover Database Environment') {
                        bat 'python scripts\\discovery\\discovery_engine.py --database mssql'
                    }
                }
            }
        }


        stage('Analyze Database Growth') {
            steps {
                script {
                    runTrackedStage('Analyze Database Growth') {
                        bat 'python scripts\\discovery\\growth_analyzer.py --database mssql'
                    }
                }
            }
        }


        stage('Analyze Migration Requirements') {
            steps {
                script {
                    runTrackedStage('Analyze Migration Requirements') {
                        bat 'python scripts\\discovery\\requirement_analyzer.py --database mssql'
                    }
                }
            }
        }


        stage('Assess Migration') {
            steps {
                script {
                    runTrackedStage('Assess Migration') {
                        bat 'scripts\\batch\\common\\migration\\run_assessment.bat mssql'
                    }
                }
            }
        }


        stage('Generate Migration Recommendations') {
            steps {
                script {
                    runTrackedStage('Generate Migration Recommendations') {
                        bat 'scripts\\batch\\common\\migration\\run_recommendation.bat mssql'
                    }
                }
            }
        }


        stage('Generate Governance Action Plan') {
            steps {
                script {
                    runTrackedStage('Generate Governance Action Plan') {
                        bat 'scripts\\batch\\common\\migration\\run_action_plan.bat mssql'
                    }
                }
            }
        }


        stage('Generate Technical Migration Report') {
            steps {
                script {
                    runTrackedStage('Generate Technical Migration Report') {
                        bat 'scripts\\batch\\common\\migration\\generate_technical_report.bat mssql'
                    }
                }
            }
        }


        stage('Generate Executive Migration Report') {
            steps {
                script {
                    runTrackedStage('Generate Executive Migration Report') {
                        bat 'scripts\\batch\\common\\migration\\generate_executive_report.bat mssql'
                    }
                }
            }
        }
    }


    post {

        success {
            echo 'MSSQL LOAD SUCCESSFUL'
        }


        failure {
            echo 'MSSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING MSSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                bat """
                    python scripts\\logging\\logger.py finalize ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}" ^
                    --status "${finalStatus}"
                """

                bat """
                    python scripts\\reporting\\generate_report.py ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """

                bat """
                    python scripts\\reporting\\generate_history.py ^
                    --database mssql ^
                    --action load ^
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mssql/load/build_${env.BUILD_NUMBER}/**, reports/mssql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mssql/**, outputs/assessments/mssql/**, outputs/assessments/assessment_report.json, metadata/profiling/mssql/**, metadata/reconciliation/mssql/**, metadata/discovery/mssql/**, metadata/assessment/mssql/**, metadata/recommendation/mssql/**, metadata/governance/mssql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}