node {

    try {

        stage('Terraform Apply') {

            bat '''
            cd terraform\\sqlserver

            if exist terraform.tfstate (
                terraform apply -auto-approve
            ) else (
                terraform init
                terraform apply -auto-approve
            )
            '''
        }

        stage('SQL Server Validation') {

            bat '''
            call scripts\\batch\\sqlserver\\validate_environment.bat
            '''
        }

        stage('Database Creation') {

            bat '''
            powershell -ExecutionPolicy Bypass ^
            -File scripts\\powershell\\sqlserver\\create_database.ps1
            '''
        }

        stage('Table Creation') {

            bat '''
            powershell -ExecutionPolicy Bypass ^
            -File scripts\\powershell\\sqlserver\\create_tables.ps1
            '''
        }

        stage('Validation') {

            bat '''
            call scripts\\batch\\sqlserver\\validate_sqlserver.bat
            '''
        }

        currentBuild.result = 'SUCCESS'
    }
    catch(Exception ex) {

        currentBuild.result = 'FAILURE'

        throw ex
    }
}