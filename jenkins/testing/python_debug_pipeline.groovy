pipeline {


agent any

environment {
    PROJECT_ROOT = 'F:\\Quantumatrix\\Projects\\DataEng\\DataPlatform-Automation'
}

stages {

    stage('Debug Python Environment') {

        steps {

            dir("${PROJECT_ROOT}") {

                bat 'type config\\python.conf'

                bat 'where python'

                bat 'where pip'

                bat 'python --version'

                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }
    }

    stage('Install Python Requirements') {

        steps {

            dir("${PROJECT_ROOT}") {

                bat 'scripts\\batch\\install_python_requirements.bat'
            }
        }
    }

    stage('Validate Python Requirements') {

        steps {

            dir("${PROJECT_ROOT}") {

                bat 'scripts\\batch\\validate_python_requirements.bat'
            }
        }
    }
}

post {

    success {
        echo 'PYTHON VALIDATION SUCCESSFUL'
    }

    failure {
        echo 'PYTHON VALIDATION FAILED'
    }

    always {
        echo 'PYTHON DEBUG PIPELINE COMPLETED'
    }
}


}
