pipeline {


agent any

stages {

    stage('Debug Python Environment') {

        steps {

            bat 'type config\\python.conf'

            bat 'where python'

            bat 'where pip'

            bat 'python --version'

            bat 'scripts\\batch\\common\\validate_python_runtime.bat'
        }
    }

    stage('Install Python Requirements') {

        steps {

            bat 'scripts\\batch\\install_python_requirements.bat'
        }
    }

    stage('Validate Python Requirements') {

        steps {

            bat 'scripts\\batch\\validate_python_requirements.bat'
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
