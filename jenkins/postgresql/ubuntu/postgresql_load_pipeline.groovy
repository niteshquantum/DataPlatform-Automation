pipeline {

    agent any

    environment {
        PIPELINE_TYPE = "POSTGRESQL_LOAD"
        DATABASE      = "POSTGRESQL"
    }

    stages {

        stage('Repository Audit') {
            steps {
                sh 'ls -la'
            }
        }

        stage('Set Script Permissions') {
    steps {
        sh 'chmod -R +x scripts/bash/'
    }
}

stage('Validate Python Runtime') {
    steps {
        sh 'scripts/bash/common/validate_python_runtime.sh'
    }
}


        stage('Validate Environment') {
            steps {
                sh 'scripts/bash/postgresql/validate_environment.sh'
            }
        }

        stage('Generate Datasets') {
            steps {
                sh 'python3 scripts/python/postgresql/generate_dataset.py'
            }
        }

        stage('Validate CSV Schema') {
            steps {
                sh 'python3 scripts/python/postgresql/testcsvschema.py'
            }
        }

        stage('Load Data') {
            steps {
                sh 'scripts/bash/postgresql/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh 'scripts/bash/postgresql/validate_loaded_data.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh 'scripts/bash/postgresql/validate_postgresql.sh'
            }
        }

    }

    post {
        success {
            echo 'PostgreSQL Load Pipeline Completed Successfully'
        }
        failure {
            echo 'PostgreSQL Load Pipeline Failed'
        }
    }
}