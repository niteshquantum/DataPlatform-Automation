def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database postgresql \
        --action load \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database postgresql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database postgresql \
            --action load \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database postgresql \
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
                    --database postgresql \
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

                        sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
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


        stage('Validate PostgreSQL') {

            steps {

                script {

                    runTrackedStage('Validate PostgreSQL') {

                        sh './scripts/bash/postgresql/setup/validate_postgresql.sh'
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

                        sh './scripts/bash/common/migration/run_data_profiling.sh postgresql'
                    }
                }
            }
        }


        stage('Load Data') {

            steps {

                script {

                    runTrackedStage('Load Data') {

                        sh './scripts/bash/postgresql/load/load_data.sh'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {

            steps {

                script {

                    runTrackedStage('Validate Loaded Data') {

                        sh './scripts/bash/postgresql/load/validate_loaded_data.sh'
                    }
                }
            }
        }


        stage('Deploy Views') {

            steps {

                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Views') {

            steps {

                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Functions') {

            steps {

                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Functions') {

            steps {

                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Stored Procedures') {

            steps {

                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Stored Procedures') {

            steps {

                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }


        stage('Deploy Triggers') {

            steps {

                sh './scripts/bash/postgresql/objects/deploy_objects.sh'
            }
        }


        stage('Validate Triggers') {

            steps {

                sh './scripts/bash/postgresql/objects/validate_objects.sh'
            }
        }


        stage('Database Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh database'
            }
        }


        stage('Schema Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh schema'
            }
        }


        stage('Table Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh table'
            }
        }


        stage('View Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh view'
            }
        }


        stage('Function Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh function'
            }
        }


        stage('Trigger Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh trigger'
            }
        }


        stage('Extension Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh extension'
            }
        }


        stage('Materialized View Inventory') {

            steps {

                sh './scripts/bash/postgresql/assessment/run_assessment.sh materialized_view'
            }
        }


        stage('Assessment Report') {

            steps {

                sh './scripts/bash/common/generate_assessment_report.sh'
            }
        }


        stage('Reconcile Source and Target Data') {

            steps {

                script {

                    runTrackedStage(
                        'Reconcile Source and Target Data'
                    ) {

                        sh './scripts/bash/common/migration/run_reconciliation.sh postgresql'
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

                        sh 'python3 scripts/discovery/discovery_engine.py --database postgresql'
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

                        sh 'python3 scripts/discovery/growth_analyzer.py --database postgresql'
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

                        sh 'python3 scripts/discovery/requirement_analyzer.py --database postgresql'
                    }
                }
            }
        }


        stage('Assess Migration') {

            steps {

                script {

                    runTrackedStage('Assess Migration') {

                        sh './scripts/bash/common/migration/run_assessment.sh postgresql'
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

                        sh './scripts/bash/common/migration/run_recommendation.sh postgresql'
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

                        sh './scripts/bash/common/migration/run_action_plan.sh postgresql'
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

                        sh './scripts/bash/common/migration/generate_technical_report.sh postgresql'
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

                        sh './scripts/bash/common/migration/generate_executive_report.sh postgresql'
                    }
                }
            }
        }
    }


    post {

        success {

            echo 'UBUNTU POSTGRESQL LOAD SUCCESSFUL'
        }


        failure {

            echo 'UBUNTU POSTGRESQL LOAD FAILED'
        }


        always {

            echo 'FINALIZING UBUNTU POSTGRESQL LOAD LOGGING AND REPORTING'

            script {

                def finalStatus = currentBuild.currentResult

                sh """
                    python3 scripts/logging/logger.py finalize \
                    --database postgresql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}" \
                    --status "${finalStatus}"
                """

                sh """
                    python3 scripts/reporting/generate_report.py \
                    --database postgresql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """

                sh """
                    python3 scripts/reporting/generate_history.py \
                    --database postgresql \
                    --action load \
                    --build-number "${env.BUILD_NUMBER}"
                """
            }


            archiveArtifacts(
                artifacts: "logs/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/postgresql/load/build_${env.BUILD_NUMBER}/**, reports/history/**, reports/migration/postgresql/**, outputs/assessments/postgresql/**, outputs/assessments/assessment_report.json, metadata/profiling/postgresql/**, metadata/reconciliation/postgresql/**, metadata/discovery/postgresql/**, metadata/assessment/postgresql/**, metadata/recommendation/postgresql/**, metadata/governance/postgresql/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}