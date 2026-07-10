pipeline {

    agent any

    parameters {

        choice(
            name: 'MIGRATION_ACTION',
            choices: [
                'MIGRATE',
                'STATUS',
                'VALIDATE',
                'ROLLBACK'
            ],
            description: 'Select MySQL migration action'
        )

        string(
            name: 'ROLLBACK_COUNT',
            defaultValue: '1',
            description: 'Number of changesets to rollback'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Migration') {
            when {
                anyOf {
                    expression { params.MIGRATION_ACTION == 'MIGRATE' }
                    expression { params.MIGRATION_ACTION == 'VALIDATE' }
                }
            }

            steps {
                bat 'scripts\\batch\\mysql\\migration\\validate_migration.bat'
            }
        }

        stage('Migration Status') {
            when {
                anyOf {
                    expression { params.MIGRATION_ACTION == 'MIGRATE' }
                    expression { params.MIGRATION_ACTION == 'STATUS' }
                }
            }

            steps {
                bat 'scripts\\batch\\mysql\\migration\\migration_status.bat'
            }
        }

        stage('Run Migration') {
            when {
                expression {
                    params.MIGRATION_ACTION == 'MIGRATE'
                }
            }

            steps {
                bat 'scripts\\batch\\mysql\\migration\\run_migration.bat'
            }
        }

        stage('Validate Migration Result') {
            when {
                expression {
                    params.MIGRATION_ACTION == 'MIGRATE'
                }
            }

            steps {
                bat 'scripts\\batch\\mysql\\migration\\validate_migration_result.bat'
            }
        }

        stage('Rollback Migration') {
            when {
                expression {
                    params.MIGRATION_ACTION == 'ROLLBACK'
                }
            }

            steps {
                bat "scripts\\batch\\mysql\\migration\\rollback_migration.bat ${params.ROLLBACK_COUNT}"
            }
        }
    }

    post {

        success {
            echo 'MYSQL MIGRATION PIPELINE COMPLETED SUCCESSFULLY'
        }

        failure {
            echo 'MYSQL MIGRATION PIPELINE FAILED'
        }

        always {
            echo 'MYSQL MIGRATION PIPELINE EXECUTION FINISHED'
        }
    }
}