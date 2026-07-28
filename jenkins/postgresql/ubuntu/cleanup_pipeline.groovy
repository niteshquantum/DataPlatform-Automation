def context = [database: 'postgresql', action: 'cleanup', operatingSystem: 'ubuntu']
pipeline {
    agent { label 'ubuntu-node' }
    parameters { choice(name: 'CLEANUP_MODE', choices: ['PRESERVE_DATA', 'DELETE_DATA'], description: 'Select PostgreSQL cleanup mode') }
    stages {
        stage('Initialize Logging') { steps { script { load('jenkins/common/standalone_pipeline_support.groovy').initialize(context) } } }
        stage('Execute POSTGRESQL CLEANUP Steps') { steps { script { def tracker = load 'jenkins/common/common_stage_tracker.groovy'; load('jenkins/common/postgresql/cleanup_steps.groovy').execute(context + [runTrackedStage: { String stageName, Closure stageBody -> tracker.track(context, stageName, stageBody) }]) } } }
    }
    post {
        success { echo 'UBUNTU POSTGRESQL CLEANUP SUCCESSFUL' }
        failure { echo 'UBUNTU POSTGRESQL CLEANUP FAILED' }
        always { script { load('jenkins/common/standalone_pipeline_support.groovy').finalize(context) }; echo 'UBUNTU POSTGRESQL CLEANUP PIPELINE COMPLETED' }
    }
}
