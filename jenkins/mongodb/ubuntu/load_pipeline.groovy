def context = [database: 'mongodb', action: 'load', operatingSystem: 'ubuntu']
pipeline {
    agent { label 'ubuntu-node' }
    stages {
        stage('Initialize Logging') { steps { script { load('jenkins/common/standalone_pipeline_support.groovy').initialize(context) } } }
        stage('Execute MONGODB LOAD Steps') { steps { script { def tracker = load 'jenkins/common/common_stage_tracker.groovy'; load('jenkins/common/mongodb/load_steps.groovy').execute(context + [runTrackedStage: { String stageName, Closure stageBody -> tracker.track(context, stageName, stageBody) }]) } } }
    }
    post {
        success { echo 'UBUNTU MONGODB LOAD SUCCESSFUL' }
        failure { echo 'UBUNTU MONGODB LOAD FAILED' }
        always { script { load('jenkins/common/standalone_pipeline_support.groovy').finalize(context) }; echo 'UBUNTU MONGODB LOAD PIPELINE COMPLETED' }
    }
}
