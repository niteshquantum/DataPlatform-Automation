

def run(Map context = [:]) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        


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


        stage('Validate PostgreSQL Requirements') {

            steps {

                script {

                    runTrackedStage(
                        'Validate PostgreSQL Requirements'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
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

                        bat 'scripts\\batch\\postgresql\\setup\\install_tools.bat'
                    }
                }
            }
        }


        stage('Validate Tools') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Tools'
                    ) {

                        bat 'scripts\\batch\\postgresql\\setup\\validate_tools.bat'
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


        stage('Assessment & Reconciliation') {

            steps {

                script {

                    runTrackedStage(
                        'Assessment & Reconciliation'
                    ) {

                        bat 'scripts\\batch\\postgresql\\assessment\\run_assessment_pipeline.bat'
                    }
                }
            }
        }


        stage('Discovery & Migration Reporting') {

            steps {

                script {

                    runTrackedStage(
                        'Discovery & Migration Reporting'
                    ) {

                        bat 'scripts\\batch\\postgresql\\migration\\run_migration_pipeline.bat'
                    }
                }
            }
        }
    
        
        }
    }
}

return this
