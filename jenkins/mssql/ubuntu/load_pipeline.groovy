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
                        find scripts/bash -type f -name "*.sh" -exec chmod +x {} \;
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

    stage('Deploy Views') {

        steps {

            script {

                runTrackedStage('Deploy Views') {

                    sh './scripts/bash/mssql/objects/deploy_objects.sh'
                }
            }
        }
    }

    stage('Validate Views') {

        steps {

            script {

                runTrackedStage('Validate Views') {

                    sh './scripts/bash/mssql/objects/validate_objects.sh'
                }
            }
        }
    }

    stage('Deploy Functions') {

        steps {

            script {

                runTrackedStage('Deploy Functions') {

                    sh './scripts/bash/mssql/objects/deploy_objects.sh'
                }
            }
        }
    }

    stage('Validate Functions') {

        steps {

            script {

                runTrackedStage('Validate Functions') {

                    sh './scripts/bash/mssql/objects/validate_objects.sh'
                }
            }
        }
    }

    stage('Deploy Stored Procedures') {

        steps {

            script {

                runTrackedStage('Deploy Stored Procedures') {

                    sh './scripts/bash/mssql/objects/deploy_objects.sh'
                }
            }
        }
    }

    stage('Validate Stored Procedures') {

        steps {

            script {

                runTrackedStage('Validate Stored Procedures') {

                    sh './scripts/bash/mssql/objects/validate_objects.sh'
                }
            }
        }
    }

    stage('Deploy Triggers') {

        steps {

            script {

                runTrackedStage('Deploy Triggers') {

                    sh './scripts/bash/mssql/objects/deploy_objects.sh'
                }
            }
        }
    }

    stage('Validate Triggers') {

        steps {

            script {

                runTrackedStage('Validate Triggers') {

                    sh './scripts/bash/mssql/objects/validate_objects.sh'
                }
            }
        }
    }

    stage('Database Inventory') {

        steps {

            script {

                runTrackedStage('Database Inventory') {

                    sh './scripts/bash/mssql/load/database_inventory.sh'
                }
            }
        }
    }

    stage('Table Inventory') {

        steps {

            script {

                runTrackedStage('Table Inventory') {

                    sh './scripts/bash/mssql/load/table_inventory.sh'
                }
            }
        }
    }

    stage('SQL Agent Inventory') {

        steps {

            script {

                runTrackedStage('SQL Agent Inventory') {

                    sh './scripts/bash/mssql/load/sql_agent.sh inventory'
                }
            }
        }
    }

    stage('SQL Agent Validation') {

        steps {

            script {

                runTrackedStage('SQL Agent Validation') {

                    sh './scripts/bash/mssql/load/sql_agent.sh validation'
                }
            }
        }
    }

    stage('SQL Agent History') {

        steps {

            script {

                runTrackedStage('SQL Agent History') {

                    sh './scripts/bash/mssql/load/sql_agent.sh history'
                }
            }
        }
    }

    stage('SQL Agent Assessment') {

        steps {

            script {

                runTrackedStage('SQL Agent Assessment') {

                    sh './scripts/bash/mssql/load/sql_agent.sh assessment'
                }
            }
        }
    }
}