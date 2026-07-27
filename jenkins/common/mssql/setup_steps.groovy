

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


        stage('Validate Java Runtime') {

            steps {

                script {

                    runTrackedStage('Validate Java Runtime') {

                        sh './scripts/bash/common/validate_java_runtime.sh'
                    }
                }
            }
        }


        stage('Install Tools') {

            steps {

                script {

                    runTrackedStage('Install Tools') {

                        sh './scripts/bash/mssql/setup/install_tools.sh'
                    }
                }
            }
        }


        stage('Check MSSQL Instance') {

            steps {

                script {

                    runTrackedStage('Check MSSQL Instance') {

                        def output = sh(
                            script: 'bash scripts/bash/mssql/setup/check_instance.sh || true',
                            returnStdout: true
                        ).trim()

                        def lines = output.split('\n')
                        def state = 'UNKNOWN'

                        for (int i = 0; i < lines.size(); i++) {

                            def line = lines[i]

                            if (line.startsWith('INSTANCE_STATE=')) {

                                state = line.split('=', 2)[1].trim()

                                break
                            }
                        }

                        env.MSSQL_INITIAL_INSTANCE_STATE = state

                        echo "Instance State: ${state}"

                        if (state == 'PORT_OCCUPIED_BY_NON_MSSQL') {

                            error "Port conflict: configured MSSQL port is occupied by a non-MSSQL process. Aborting setup."
                        }

                        if (state == 'UNKNOWN') {

                            error "Unknown MSSQL instance state detected. Aborting setup."
                        }
                    }
                }
            }
        }


        stage('Install MSSQL') {

            when {
                expression {
                    return env.MSSQL_INITIAL_INSTANCE_STATE == 'NO_INSTANCE'
                }
            }

            steps {

                script {

                    runTrackedStage('Install MSSQL') {

                        sh './scripts/bash/mssql/setup/install_mssql.sh'
                    }
                }
            }
        }


        stage('Deploy MSSQL') {

            when {
                expression {
                    return env.MSSQL_INITIAL_INSTANCE_STATE == 'NO_INSTANCE'
                }
            }

            steps {

                script {

                    runTrackedStage('Deploy MSSQL') {

                        sh './scripts/bash/mssql/setup/deploy_mssql.sh'
                    }
                }
            }
        }


        stage('Start MSSQL') {

            when {
                expression {
                    def state = env.MSSQL_INITIAL_INSTANCE_STATE
                    return state == 'INSTANCE_INSTALLED_BUT_STOPPED' || state == 'NO_INSTANCE'
                }
            }

            steps {

                script {

                    runTrackedStage('Start MSSQL') {

                        sh './scripts/bash/mssql/setup/start_mssql.sh'
                    }
                }
            }
        }


        stage('Configure Global MSSQL') {

            when {
                expression {
                    return env.MSSQL_INITIAL_INSTANCE_STATE != 'INSTANCE_RUNNING_AND_USABLE'
                }
            }

            steps {

                script {

                    runTrackedStage('Configure Global MSSQL') {

                        sh 'bash ./scripts/bash/mssql/setup/configure_global_mssql.sh'
                    }
                }
            }
        }


        stage('Configure Database RBAC') {
            steps { script { runTrackedStage('Configure Database RBAC') { sh './scripts/bash/mssql/setup/create_database.sh'; sh './scripts/bash/mssql/rbac/configure_database_rbac.sh'; sh './scripts/bash/mssql/setup/run_liquibase.sh' } } }
        }

        stage('Validate Environment') {

            steps {

                script {

                    runTrackedStage('Validate Environment') {

                        sh './scripts/bash/mssql/setup/validate_environment.sh'
                    }
                }
            }
        }
    
        
        }
    }
}

return this
