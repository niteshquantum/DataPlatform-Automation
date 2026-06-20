node {

    try {

        stage('Checkout Repository') {
            checkout scm
        }

        stage('Repository Audit') {

            bat '''
            echo =====================================
            echo WORKSPACE
            echo =====================================
            echo %WORKSPACE%

            echo =====================================
            echo ROOT
            echo =====================================
            dir

            echo =====================================
            echo TERRAFORM
            echo =====================================
            dir terraform

            echo =====================================
            echo SQLSERVER
            echo =====================================
            dir terraform\\sqlserver

            if not exist terraform\\sqlserver\\main.tf (
                echo [FAIL] terraform\\sqlserver\\main.tf missing
                exit /b 1
            )

            if not exist terraform\\sqlserver\\variables.tf (
                echo [FAIL] terraform\\sqlserver\\variables.tf missing
                exit /b 1
            )

            if not exist terraform\\sqlserver\\terraform.tfvars (
                echo [FAIL] terraform\\sqlserver\\terraform.tfvars missing
                exit /b 1
            )

            if not exist config\\sqlserver.conf (
                echo [FAIL] config\\sqlserver.conf missing
                exit /b 1
            )

            echo [PASS] Repository validation successful
            '''
        }

        stage('Validate Python Runtime') {

            bat '''
            call scripts\\batch\\common\\validate_python_runtime.bat
            '''
        }

        stage('Install Python Requirements') {

            bat '''
            pip install -r requirements.txt
            '''
        }

        stage('Validate Python Requirements') {

            bat '''
            python -c "import pandas"
            '''
        }

        stage('Validate Java Runtime') {

            bat '''
            call scripts\\batch\\common\\validate_java_runtime.bat
            '''
        }

        stage('Install Tools') {

            bat '''
            call scripts\\batch\\common\\install_tools.bat
            '''
        }

        stage('Deploy SQL Server') {

            bat '''
            pushd terraform\\sqlserver

            if exist terraform.tfstate (
                terraform apply -auto-approve
            ) else (
                terraform init
                terraform apply -auto-approve
            )

            popd
            '''
        }

        stage('Create Database') {

            bat '''
            echo Database already created by Terraform
            '''
        }

        stage('Validate Environment') {

            bat '''
            call scripts\\batch\\sqlserver\\validate_environment.bat
            '''
        }

        stage('Run Liquibase') {

            bat '''
            call scripts\\batch\\sqlserver\\run_liquibase.bat
            '''
        }

        stage('Validate SQL Server') {

            bat '''
            call scripts\\batch\\sqlserver\\validate_sqlserver.bat
            '''
        }

        currentBuild.result = 'SUCCESS'

    } catch(Exception ex) {

        currentBuild.result = 'FAILURE'
        throw ex
    }
}