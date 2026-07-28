def context = [database: 'mysql', action: 'cleanup', operatingSystem: 'ubuntu']
pipeline {
    agent { label 'ubuntu-node' }
    parameters { choice(name: 'CLEANUP_MODE', choices: ['PRESERVE_DATA', 'DELETE_DATA'], description: 'Select MySQL cleanup mode') }
    stages {
        stage('Initialize Logging') { steps { script { load('jenkins/common/standalone_pipeline_support.groovy').initialize(context) } } }
        stage('Execute MYSQL CLEANUP Steps') { steps { script { def tracker = load 'jenkins/common/common_stage_tracker.groovy'; load('jenkins/common/mysql/cleanup_steps.groovy').execute(context + [runTrackedStage: { String stageName, Closure stageBody -> tracker.track(context, stageName, stageBody) }]) } } }
    }
    post {
        success { echo 'MYSQL UBUNTU CLEANUP SUCCESSFUL' }
        failure { echo 'MYSQL UBUNTU CLEANUP FAILED' }
        always { script { load('jenkins/common/standalone_pipeline_support.groovy').finalize(context) }; echo 'MYSQL UBUNTU CLEANUP PIPELINE COMPLETED' }
    }
}
