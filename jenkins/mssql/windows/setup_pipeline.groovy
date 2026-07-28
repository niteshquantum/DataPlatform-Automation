def context = [database: 'mssql', action: 'setup', operatingSystem: 'windows']
pipeline {
    agent { label 'windows-node' }
    stages {
        stage('Initialize Logging') { steps { script { load('jenkins/common/standalone_pipeline_support.groovy').initialize(context) } } }
        stage('Execute MSSQL SETUP Steps') { steps { script { def tracker = load 'jenkins/common/common_stage_tracker.groovy'; load('jenkins/common/mssql/setup_steps.groovy').execute(context + [runTrackedStage: { String stageName, Closure stageBody -> tracker.track(context, stageName, stageBody) }]) } } }
    }
    post {
        success { echo 'WINDOWS MSSQL SETUP SUCCESSFUL' }
        failure { echo 'WINDOWS MSSQL SETUP FAILED' }
        always { script { load('jenkins/common/standalone_pipeline_support.groovy').finalize(context) }; echo 'WINDOWS MSSQL SETUP PIPELINE COMPLETED' }
    }
}
