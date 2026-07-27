

def run(Map context = [:]) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        stage('Set Permissions') {

            steps {

                sh '''
                    find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                '''
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


        stage('Install Python Requirements') {

            steps {

                script {

                    runTrackedStage('Install Python Requirements') {

                        sh './scripts/bash/mssql/setup/install_python_requirements.sh'
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


        stage('Validate Tools') {

            steps {

                script {

                    runTrackedStage('Validate Tools') {

                        sh './scripts/bash/mssql/validate_tools.sh'
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


        stage('Validate MSSQL Instance') {

            steps {

                script {

                    runTrackedStage('Validate MSSQL Instance') {

                        sh './scripts/bash/mssql/setup/validate_mssql_instance.sh'
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

                        sh './scripts/bash/common/run_data_profiling.sh mssql'
                    }
                }
            }
        }


        stage('Create Database') {

            steps {

                script {

                    runTrackedStage('Create Database') {

                        sh './scripts/bash/mssql/setup/create_database.sh'
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


        stage('Deploy Database Objects') {

            steps {

                script {

                    runTrackedStage('Deploy Database Objects') {

                        sh './scripts/bash/mssql/objects/deploy_objects.sh'
                    }
                }
            }
        }


        stage('Validate Database Objects') {

            steps {

                script {

                    runTrackedStage('Validate Database Objects') {

                        sh './scripts/bash/mssql/objects/validate_objects.sh'
                    }
                }
            }
        }


        stage('Database Assessment') {

            steps {

                script {

                    runTrackedStage('Database Assessment') {

                        sh './scripts/bash/mssql/assessment/run_assessment.sh all'
                    }
                }
            }
        }


        stage('Assessment Report') {

            steps {

                script {

                    runTrackedStage('Assessment Report') {

                        sh './scripts/bash/common/generate_assessment_report.sh'
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

                        sh './scripts/bash/common/run_reconciliation.sh mssql'
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

                        sh 'python3 scripts/discovery/discovery_engine.py --database mssql'
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

                        sh 'python3 scripts/discovery/growth_analyzer.py --database mssql'
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

                        sh 'python3 scripts/discovery/requirement_analyzer.py --database mssql'
                    }
                }
            }
        }


        stage('Assess Migration') {

            steps {

                script {

                    runTrackedStage('Assess Migration') {

                        sh './scripts/bash/common/run_assessment.sh mssql'
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

                        sh './scripts/bash/common/run_recommendation.sh mssql'
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

                        sh './scripts/bash/common/run_action_plan.sh mssql'
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

                        sh './scripts/bash/common/generate_technical_report.sh mssql'
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

                        sh './scripts/bash/common/generate_executive_report.sh mssql'
                    }
                }
            }
        }
    
        
        }
    }
}

return this
