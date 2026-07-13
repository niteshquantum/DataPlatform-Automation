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
                bat 'scripts\\batch\\mssql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\start_mssql.bat'
            }
        }

        stage('Validate SQL Server') {
            steps {
                bat 'scripts\\batch\\mssql\\setup\\validate_mssql.bat'
            }
        }

        

        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mssql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mssql\\load\\validate_loaded_data.bat'
            }
        }

        stage('Deploy Views') { steps { bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat' } }
        stage('Validate Views') { steps { bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat' } }
        stage('Deploy Functions') { steps { bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat' } }
        stage('Validate Functions') { steps { bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat' } }
        stage('Deploy Stored Procedures') { steps { bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat' } }
        stage('Validate Stored Procedures') { steps { bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat' } }
        stage('Deploy Triggers') { steps { bat 'scripts\\batch\\mssql\\objects\\deploy_objects.bat' } }
        stage('Validate Triggers') { steps { bat 'scripts\\batch\\mssql\\objects\\validate_objects.bat' } }
        stage('Database Inventory') { steps { bat 'scripts\\batch\\mssql\\load\\database_inventory.bat' } }
        stage('Table Inventory') { steps { bat 'scripts\\batch\\mssql\\load\\table_inventory.bat' } }
        stage('SQL Agent Inventory') { steps { bat 'scripts\\batch\\mssql\\load\\sql_agent.bat inventory' } }
        stage('SQL Agent Validation') { steps { bat 'scripts\\batch\\mssql\\load\\sql_agent.bat validation' } }
        stage('SQL Agent History') { steps { bat 'scripts\\batch\\mssql\\load\\sql_agent.bat history' } }
        stage('SQL Agent Assessment') { steps { bat 'scripts\\batch\\mssql\\load\\sql_agent.bat assessment' } }

    }

    post {

        success {
            echo 'MSSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'MSSQL LOAD FAILED'
        }

        always {
            echo 'MSSQL LOAD PIPELINE COMPLETED'
        }

    }

}
