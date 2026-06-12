pipeline {

agent any

stages {

    stage('Install Tools') {

        steps {

            bat 'scripts\\batch\\common\\install_tools.bat'
        }
    }

    stage('Validate Tools') {

        steps {

            bat 'scripts\\batch\\common\\validate_tools.bat'
        }
    }
}

post {

    success {
        echo 'TOOLS VALIDATION SUCCESSFUL'
    }

    failure {
        echo 'TOOLS VALIDATION FAILED'
    }

    always {
        echo 'TOOLS DEBUG PIPELINE COMPLETED'
    }
}


}
