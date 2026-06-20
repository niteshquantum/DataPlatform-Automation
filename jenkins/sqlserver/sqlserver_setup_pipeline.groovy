node {

stage('Checkout Repository') {

    checkout scm
}
try {

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

    stage('Install Tools') {

    bat '''
    call scripts\\batch\\common\\install_tools.bat
    '''
    }

    stage('Terraform Apply') {

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

    stage('SQL Server Validation') {

        bat '''
        call scripts\\batch\\sqlserver\\validate_environment.bat
        '''
    }

   

    stage('Run Liquibase') {

    bat '''
    call scripts\\batch\\sqlserver\\run_liquibase.bat
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
