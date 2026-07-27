

def run(Map context = [:]) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }
    def runtime = load 'jenkins/scripted_module_runtime.groovy'
    runtime.execute {
        stages {


        


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


        stage('Load Data') {

            steps {

                script {

                    runTrackedStage(
                        'Load Data'
                    ) {

                        bat 'scripts\\batch\\mongodb\\load\\load_data.bat'
                    }
                }
            }
        }


        stage('Validate Loaded Data') {

            steps {

                script {

                    runTrackedStage(
                        'Validate Loaded Data'
                    ) {

                        bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
                    }
                }
            }
        }


        /*
        ============================================================
        OPTIONAL POST-PROCESSING
        Assessment/reporting is intentionally not part of CORE LOAD.
        Execute through dedicated assessment/reporting entry point.
        ============================================================
        */


        stage('Database Assessment') {

            when {

                expression {
                    return params.RUN_ASSESSMENT == 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Database Assessment'
                    ) {

                        bat 'scripts\\batch\\mongodb\\assessment\\run_assessment.bat all'
                    }
                }
            }
        }


        stage('Assessment Report') {

            when {

                expression {
                    return params.RUN_ASSESSMENT == 'true'
                }
            }

            steps {

                script {

                    runTrackedStage(
                        'Assessment Report'
                    ) {

                        bat 'scripts\\batch\\common\\generate_assessment_report.bat'
                    }
                }
            }
        }
    
        
        }
    }
}

return this
