def runTrackedStage(String stageName, Closure stageBody) {

    sh """
        python3 scripts/logging/logger.py stage-start \
        --database mssql \
        --action setup \
        --build-number "${env.BUILD_NUMBER}" \
        --stage-name "${stageName}"
    """

    try {

        stageBody()

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status SUCCESS
        """

    } catch (Exception error) {

        sh """
            python3 scripts/logging/logger.py stage-end \
            --database mssql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --stage-name "${stageName}" \
            --status FAILURE
        """

        sh """
            python3 scripts/logging/logger.py set-error \
            --database mssql \
            --action setup \
            --build-number "${env.BUILD_NUMBER}" \
            --failed-stage "${stageName}" \
            --message "Stage execution failed"
        """

        throw error
    }
}


pipeline {

    agent {
        label 'ubuntu-node'
    }

    options {
        disableConcurrentBuilds()
    }


    stages {

        stage('Set Permissions') {

            steps {

                sh '''
                    find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                '''
            }
        }
        
        stage('Initialize Logging') {

            steps {

                sh """
                    python3 scripts/logging/logger.py init \
                    --database mssql \
                    --action setup \
                    --os ubuntu \
                    --build-number "${env.BUILD_NUMBER}" \
                    --job-name "${env.JOB_NAME}" \
                    --build-url "${env.BUILD_URL}"
                """
            }
        }
        
        stage('MSSQL Setup') {

            steps {

                script {

                    runTrackedStage('MSSQL Setup') {

                        sh 'bash scripts/bash/mssql/mssql_setup_pipeline.sh'
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'UBUNTU MSSQL SETUP SUCCESSFUL'
        }
        failure {
            echo 'UBUNTU MSSQL SETUP FAILED'
        }
        always {
            echo 'FINALIZING UBUNTU MSSQL SETUP LOGGING AND REPORTING'
            script {
                def finalStatus = currentBuild.currentResult
                sh """
                    python3 scripts/logging/logger.py finalize \
                        --database mssql \
                        --action setup \
                        --build-number "${env.BUILD_NUMBER}" \
                        --status "${finalStatus}"
                """
                sh """
                    python3 scripts/reporting/generate_report.py \
                        --database mssql \
                        --action setup \
                        --build-number "${env.BUILD_NUMBER}"
                """
                sh """
                    python3 scripts/reporting/generate_history.py \
                        --database mssql \
                        --action setup \
                        --build-number "${env.BUILD_NUMBER}"
                """
            }
            archiveArtifacts(
                artifacts: "logs/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/mssql/setup/build_${env.BUILD_NUMBER}/**, reports/history/**", 
                fingerprint: true, 
                allowEmptyArchive: true
            )
            echo 'UBUNTU MSSQL SETUP PIPELINE COMPLETED'
        }
    }
}
