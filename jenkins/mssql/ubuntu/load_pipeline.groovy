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

        stage('Validate CSV') {
            steps {
                script {
                    runTrackedStage('Validate CSV') {
                        sh './scripts/bash/mssql/load/validate_csv.sh'
                    }
                }
            }
        }

        stage('Deploy Views') { steps { sh './scripts/bash/mssql/objects/deploy_objects.sh' } }
        stage('Validate Views') { steps { sh './scripts/bash/mssql/objects/validate_objects.sh' } }
        stage('Deploy Functions') { steps { sh './scripts/bash/mssql/objects/deploy_objects.sh' } }
        stage('Validate Functions') { steps { sh './scripts/bash/mssql/objects/validate_objects.sh' } }
        stage('Deploy Stored Procedures') { steps { sh './scripts/bash/mssql/objects/deploy_objects.sh' } }
        stage('Validate Stored Procedures') { steps { sh './scripts/bash/mssql/objects/validate_objects.sh' } }
        stage('Deploy Triggers') { steps { sh './scripts/bash/mssql/objects/deploy_objects.sh' } }
        stage('Validate Triggers') { steps { sh './scripts/bash/mssql/objects/validate_objects.sh' } }
        stage('Database Inventory') { steps { sh './scripts/bash/mssql/load/database_inventory.sh' } }
        stage('Table Inventory') { steps { sh './scripts/bash/mssql/load/table_inventory.sh' } }
        stage('SQL Agent Inventory') { steps { sh './scripts/bash/mssql/load/sql_agent.sh inventory' } }
        stage('SQL Agent Validation') { steps { sh './scripts/bash/mssql/load/sql_agent.sh validation' } }
        stage('SQL Agent History') { steps { sh './scripts/bash/mssql/load/sql_agent.sh history' } }
        stage('SQL Agent Assessment') { steps { sh './scripts/bash/mssql/load/sql_agent.sh assessment' } }
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
                artifacts: "logs/mssql/load/build_${env.BUILD_NUMBER}/**, reports/mssql/load/build_${env.BUILD_NUMBER}/**, reports/history/**",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo 'UBUNTU MSSQL LOAD PIPELINE COMPLETED'
        }
    }
}



