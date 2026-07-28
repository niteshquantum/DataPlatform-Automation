

def execute(Map context) {
    def runTrackedStage = context.runTrackedStage ?: { String stageName, Closure stageBody -> stageBody() }


        


        stage('Download Dataset') {



                    runTrackedStage(
                        'Download Dataset'
                    ) {

                        bat 'scripts\\batch\\common\\download_dataset.bat'
                    }
        }


        stage('Load Data') {



                    runTrackedStage(
                        'Load Data'
                    ) {

                        bat 'scripts\\batch\\mongodb\\load\\load_data.bat'
                    }
        }


        stage('Validate Loaded Data') {



                    runTrackedStage(
                        'Validate Loaded Data'
                    ) {

                        bat 'scripts\\batch\\mongodb\\load\\validate_loaded_data.bat'
                    }
        }


        /*
        ============================================================
        OPTIONAL POST-PROCESSING
        Assessment/reporting is intentionally not part of CORE LOAD.
        Execute through dedicated assessment/reporting entry point.
        ============================================================
        */


        if ({ -> return params.RUN_ASSESSMENT == 'true' }()) {
            stage('Database Assessment') {runTrackedStage(
                        'Database Assessment'
                    ) {

                        bat 'scripts\\batch\\mongodb\\assessment\\run_assessment.bat all'
                    }
                }
        }


        if ({ -> return params.RUN_ASSESSMENT == 'true' }()) {
            stage('Assessment Report') {runTrackedStage(
                        'Assessment Report'
                    ) {

                        bat 'scripts\\batch\\common\\generate_assessment_report.bat'
}
            }}
            }

return this
