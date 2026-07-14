def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mssql \
        --action load \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mssql \
            --action load \
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
                    --database mssql \
                    --action load \
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


        stage('Validate Python Requirements') {
            steps {
                script {
                    runTrackedStage('Validate Python Requirements') {
                        sh './scripts/bash/mssql/setup/validate_python_requirements.sh'
                    }
                }
            }
        }


        stage('Start MSSQL') {
            steps {
                script {
                    runTrackedStage('Start MSSQL') {
                        sh './scripts/bash/mssql/setup/start_mssql.sh'
                    }
                }
            }
        }


        stage('Validate MSSQL') {
            steps {
                script {
                    runTrackedStage('Validate MSSQL') {
                        sh './scripts/bash/mssql/setup/validate_mssql.sh'
                    }
                }
            }
        }


        stage('Download Dataset') {
            steps {
                script {
                    runTrackedStage('Download Dataset') {
                        sh './scripts/bash/common/download_dataset.sh'
                    }
                }
            }
        }


        stage('Profile Source Data') {
            steps {
                script {
                    runTrackedStage('Profile Source Data') {
                        sh './scripts/bash/common/migration/run_data_profiling.sh mssql'
                    }
                }
            }
        }


        stage('Load Data') {
            steps {
                script {
                    runTrackedStage('Load Data') {
                        sh './scripts/bash/mssql/load/load_data.sh'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {
            steps {
                script {
                    runTrackedStage('Validate Loaded Data') {
                        sh './scripts/bash/mssql/load/validate_loaded_data.sh'
                    }
                }
            }
        }


        stage('Deploy Views') {
            steps {
                sh './scripts/bash/mssql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Views') {
            steps {
                sh './scripts/bash/mssql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Functions') {
            steps {
                sh './scripts/bash/mssql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Functions') {
            steps {
                sh './scripts/bash/mssql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Stored Procedures') {
            steps {
                sh './scripts/bash/mssql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Stored Procedures') {
            steps {
                sh './scripts/bash/mssql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Triggers') {
            steps {
                sh './scripts/bash/mssql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Triggers') {
            steps {
                sh './scripts/bash/mssql/objects/validate_objects.sh'
            }
        }


        stage('Database Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh database'
            }
        }


        stage('Schema Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh schema'
            }
        }


        stage('Table Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh table'
            }
        }


        stage('View Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh view'
            }
        }


        stage('Stored Procedure Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh procedure'
            }
        }


        stage('Function Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh function'
            }
        }


        stage('Trigger Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh trigger'
            }
        }


        stage('SQL Agent Inventory') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh sql_agent_inventory'
            }
        }


        stage('SQL Agent Validation') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh sql_agent_validation'
            }
        }


        stage('SQL Agent History') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh sql_agent_history'
            }
        }


        stage('SQL Agent Assessment') {
            steps {
                sh './scripts/bash/mssql/assessment/run_assessment.sh sql_agent_assessment'
            }
        }


        stage('Final Assessment Report') {
            steps {
                sh './scripts/bash/common/generate_assessment_report.sh'
            }
        }


        stage('Reconcile Source and Target Data') {
            steps {
                script {
                    runTrackedStage('Reconcile Source and Target Data') {
                        sh './scripts/bash/common/migration/run_reconciliation.sh mssql'
                    }
                }
            }
        }


        stage('Discover Database Environment') {
            steps {
                script {
                    runTrackedStage('Discover Database Environment') {
                        sh 'python3 scripts/discovery/discovery_engine.py --database mssql'
                    }
                }
            }
        }


        stage('Analyze Database Growth') {
            steps {
                script {
                    runTrackedStage('Analyze Database Growth') {
                        sh 'python3 scripts/discovery/growth_analyzer.py --database mssql'
                    }
                }
            }
        }


        stage('Analyze Migration Requirements') {
            steps {
                script {
                    runTrackedStage('Analyze Migration Requirements') {
                        sh 'python3 scripts/discovery/requirement_analyzer.py --database mssql'
                    }
                }
            }
        }


        stage('Assess Migration') {
            steps {
                script {
                    runTrackedStage('Assess Migration') {
                        sh './scripts/bash/common/migration/run_assessment.sh mssql'
                    }
                }
            }
        }


        stage('Generate Migration Recommendations') {
            steps {
                script {
                    runTrackedStage('Generate Migration Recommendations') {
                        sh './scripts/bash/common/migration/run_recommendation.sh mssql'
                    }
                }
            }
        }


        stage('Generate Governance Action Plan') {
            steps {
                script {
                    runTrackedStage('Generate Governance Action Plan') {
                        sh './scripts/bash/common/migration/run_action_plan.sh mssql'
                    }
                }
            }
        }


        stage('Generate Technical Migration Report') {
            steps {
                script {
                    runTrackedStage('Generate Technical Migration Report') {
                        sh './scripts/bash/common/migration/generate_technical_report.sh mssql'
                    }
                }
            }
        }


        stage('Generate Executive Migration Report') {
            steps {
                script {
                    runTrackedStage('Generate Executive Migration Report') {
                        sh './scripts/bash/common/migration/generate_executive_report.sh mssql'
                    }
                }
            }
        }
    }


    post {

        success {
            echo 'UBUNTU MSSQL LOAD SUCCESSFUL'
        }


        failure {
            echo 'UBUNTU MSSQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU MSSQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database mssql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/mssql/load/build_${env.BUILD_NUMBER}/**, reports/mssql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/mssql/**, outputs/assessments/mssql/**, outputs/assessments/assessment_report.json, metadata/profiling/mssql/**, metadata/reconciliation/mssql/**, metadata/discovery/mssql/**, metadata/assessment/mssql/**, metadata/recommendation/mssql/**, metadata/governance/mssql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}