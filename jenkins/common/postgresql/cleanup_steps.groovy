

def execute(Map context) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        


        stage('Run PostgreSQL Cleanup') {

            steps {
                script {
                    runTrackedStage('Run PostgreSQL Cleanup') {
                        withEnv([
                            "CLEANUP_MODE=${params.CLEANUP_MODE}"
                        ]) {
                            bat 'scripts\\batch\\postgresql\\cleanup\\postgresql_cleanup_pipeline.bat'
                        }
                    }
                }
            }
        }
    
        
        }
    }
}

return this
