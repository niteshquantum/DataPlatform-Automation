node {

    try {

        stage('Dataset Generation') {

            bat '''
            python scripts\\python\\sqlserver\\generate_dataset.py
            '''
        }

        stage('Data Load') {

            bat '''
            python scripts\\python\\sqlserver\\load_data.py
            '''
        }

        stage('Data Validation') {

            bat '''
            python scripts\\python\\sqlserver\\validate_data.py
            '''
        }

        currentBuild.result = 'SUCCESS'
    }
    catch(Exception ex) {

        currentBuild.result = 'FAILURE'

        throw ex
    }
}