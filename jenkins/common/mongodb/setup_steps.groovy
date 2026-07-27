


def getInstanceState() {

    def output = bat(
        script: 'scripts\\batch\\mongodb\\setup\\check_instance.bat',
        returnStdout: true
    ).trim()

    def state = 'UNKNOWN'

    def lines = output.split('\n')

    for (int i = 0; i < lines.size(); i++) {

        def line = lines[i].replace('\r', '')

        if (line.startsWith('INSTANCE_STATE=')) {

            state = line.split('=', 2)[1].trim()

            break
        }
    }

    def allowedStates = [
        'INSTANCE_RUNNING_AND_USABLE',
        'INSTANCE_INSTALLED_BUT_STOPPED',
        'NO_INSTANCE',
        'PORT_OCCUPIED_BY_NON_MONGODB'
    ]

    if (!allowedStates.contains(state)) {

        error "Invalid MongoDB instance state detected: >${state}<"
    }

    return state
}

def execute(Map context) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }


        


        stage('Check Administrator Privileges') {



                    runTrackedStage(
                        'Check Administrator Privileges'
                    ) {

                        def adminStatus = bat(
                            script: 'scripts\\batch\\common\\check_admin_privileges.bat',
                            returnStatus: true
                        )

                        if (adminStatus == 0) {

                            writeFile(
                                file: 'admin_status.txt',
                                text: 'true'
                            )

                            echo 'Administrator privileges available.'
                            echo 'Global Mongosh and MongoDB Service configuration will be enabled.'

                        } else {

                            writeFile(
                                file: 'admin_status.txt',
                                text: 'false'
                            )

                            echo 'Administrator privileges not available.'
                            echo 'Global Mongosh and MongoDB Service configuration will be skipped.'
                            echo 'MongoDB will run using project-local mode.'
                        }

                        def adminResult = readFile(
                            'admin_status.txt'
                        ).trim()

                        echo "ADMIN STATUS = ${adminResult}"

                        bat """
                            python scripts\\logging\\logger.py set-environment ^
                            --database mongodb ^
                            --action setup ^
                            --build-number "${env.BUILD_NUMBER}" ^
                            --administrator-privileges "${adminResult}"
                        """
                    }
        }


        // stage('Validate Python Runtime') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Validate Python Runtime'
        //             ) {

        //                 bat 'scripts\\batch\\common\\validate_python_runtime.bat'
        //             }
        //         }
        //     }
        // }


        // stage('Install Python Requirements') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Install Python Requirements'
        //             ) {

        //                 bat 'scripts\\batch\\mongodb\\setup\\install_python_requirements.bat'
        //             }
        //         }
        //     }
        // }


        // stage('Validate Python Requirements') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Validate Python Requirements'
        //             ) {

        //                 bat 'scripts\\batch\\mongodb\\setup\\validate_python_requirements.bat'
        //             }
        //         }
        //     }
        // }


        // stage('Validate Java Runtime') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Validate Java Runtime'
        //             ) {

        //                 bat 'scripts\\batch\\common\\validate_java_runtime.bat'
        //             }
        //         }
        //     }
        // }


        // stage('Install Tools') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Install Tools'
        //             ) {

        //                 bat 'scripts\\batch\\mongodb\\setup\\install_tools.bat'
        //             }
        //         }
        //     }
        // }


        // stage('Validate Tools') {

        //     steps {

        //         script {

        //             runTrackedStage(
        //                 'Validate Tools'
        //             ) {

        //                 bat 'scripts\\batch\\mongodb\\setup\\validate_tools.bat'
        //             }
        //         }
        //     }
        // }


        stage('Check MongoDB Instance') {



                    runTrackedStage(
                        'Check MongoDB Instance'
                    ) {

                        def instanceState = getInstanceState()

                        env.MONGODB_INITIAL_INSTANCE_STATE = instanceState

                        echo "Initial Instance State: >${instanceState}<"
                        echo "State length: ${instanceState.length()}"
                        echo "Deploy condition (NO_INSTANCE): ${instanceState == 'NO_INSTANCE'}"
                    }
        }


        if ({ -> return env.MONGODB_INITIAL_INSTANCE_STATE == 'NO_INSTANCE' }()) {
            stage('Deploy MongoDB') {runTrackedStage(
                        'Deploy MongoDB'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\run_terraform.bat'
                    }
        }


        if ({ -> return (
                        readFile('admin_status.txt').trim() == 'true' &&
                        env.MONGODB_INITIAL_INSTANCE_STATE == 'NO_INSTANCE'
                    ) }()) {
            stage('Configure Global Mongosh') {runTrackedStage(
                        'Configure Global Mongosh'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring Global Mongosh command...'

                        bat 'scripts\\batch\\mongodb\\setup\\configure_global_mongosh.bat'
                    }
        }


        if ({ -> return (
                        readFile('admin_status.txt').trim() == 'true' &&
                        env.MONGODB_INITIAL_INSTANCE_STATE == 'NO_INSTANCE'
                    ) }()) {
            stage('Configure MongoDB Service') {runTrackedStage(
                        'Configure MongoDB Service'
                    ) {

                        echo 'Administrator privileges available.'
                        echo 'Configuring MongoDB Windows Service...'

                        bat 'scripts\\batch\\mongodb\\setup\\configure_mongodb_service.bat'
                    }
        }


        if ({ -> return (
                        env.MONGODB_INITIAL_INSTANCE_STATE == 'INSTANCE_INSTALLED_BUT_STOPPED' ||
                        env.MONGODB_INITIAL_INSTANCE_STATE == 'NO_INSTANCE'
                    ) }()) {
            stage('Start MongoDB') {runTrackedStage(
                        'Start MongoDB'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\start_mongodb.bat'
                    }
        }


        stage('Validate MongoDB Port') {



                    runTrackedStage(
                        'Validate MongoDB Port'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\validate_port.bat'
                    }
        }


        stage('Configure Database RBAC') {
runTrackedStage('Configure Database RBAC') { bat 'scripts\\batch\\mongodb\\rbac\\configure_database_rbac.bat' }
        }

        stage('Validate MongoDB Instance') {



                    runTrackedStage(
                        'Validate MongoDB Instance'
                    ) {

                        bat 'scripts\\batch\\mongodb\\setup\\validate_mongodb.bat'
}

return this
