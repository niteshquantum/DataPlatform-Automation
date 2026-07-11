pipeline {

    agent any

    stages {

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start MySQL Service') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
            }
        }

        stage('Validate MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_mysql.bat'
            }
        }


        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Validate CSV') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\validate_csv.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\validate_loaded_data.bat'
            }
        }

        stage('Deploy Views') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Views') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Functions') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Functions') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }

        stage('Deploy Triggers') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
            }
        }

        stage('Validate Triggers') {
            steps {
                bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
            }
        }
    }

    post {

        success {
            echo 'MYSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'MYSQL LOAD FAILED'
        }

        always {
            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
