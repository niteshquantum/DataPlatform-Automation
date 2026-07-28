def context = [database: 'mysql', action: 'setup', operatingSystem: 'windows']
pipeline {
    agent { label 'windows-node' }
    stages {
        stage('Initialize Logging') { steps { script { load('jenkins/common/standalone_pipeline_support.groovy').initialize(context) } } }
        stage('Execute MYSQL SETUP Steps') { steps { script { def tracker = load 'jenkins/common/common_stage_tracker.groovy'; load('jenkins/common/mysql/setup_steps.groovy').execute(context + [runTrackedStage: { String stageName, Closure stageBody -> tracker.track(context, stageName, stageBody) }]) } } }
    }
    post {
        success { echo 'WINDOWS MYSQL SETUP SUCCESSFUL' }
        failure { echo 'WINDOWS MYSQL SETUP FAILED' }
        always { script { load('jenkins/common/standalone_pipeline_support.groovy').finalize(context) }; echo 'WINDOWS MYSQL SETUP PIPELINE COMPLETED' }
    }
}
