

def run(Map context = [:]) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        


        stage('Run MongoDB Cleanup') {

            steps {
                script {
                    runTrackedStage('Run MongoDB Cleanup') {
                        withEnv([
                            "CLEANUP_MODE=${params.CLEANUP_MODE}"
                        ]) {
                            bat 'scripts\\batch\\mongodb\\cleanup\\mongodb_cleanup_pipeline.bat'
                        }
                    }
                }
            }
        }
    
        
        }
    }
}

return this
