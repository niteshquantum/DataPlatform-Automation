

def run(Map context = [:]) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        stage('Validate Cleanup Parameters') {

            steps {

                script {
                    runTrackedStage('Validate Cleanup Parameters') {
                        if (
                            params.CLEANUP_MODE != 'PRESERVE_DATA' &&
                            params.CLEANUP_MODE != 'DELETE_DATA'
                        ) {
                            error("Invalid CLEANUP_MODE: ${params.CLEANUP_MODE}")
                        }

                        echo """
=====================================
MYSQL UBUNTU CLEANUP PARAMETERS
=====================================

Cleanup Mode : ${params.CLEANUP_MODE}
"""
                    }
                }
            }
        }

        stage('Run MySQL Cleanup') {

            steps {
                script {
                    runTrackedStage('Run MySQL Cleanup') {
                        withEnv([
                            "CLEANUP_MODE=${params.CLEANUP_MODE}"
                        ]) {
                            sh '''
                        echo
                        echo "====================================="
                        echo "RUNNING MYSQL UBUNTU CLEANUP"
                        echo "====================================="
                        echo

                        bash scripts/bash/mysql/cleanup/mysql_cleanup_pipeline.sh

                        echo
                        echo "====================================="
                        echo "MYSQL UBUNTU CLEANUP COMPLETED"
                        echo "====================================="
                        echo
                    '''
                        }
                    }
                }
            }
        }
    
        
        }
    }
}

return this
