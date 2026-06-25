Data Platform Automation

Terraform
Liquibase
Jenkins
Python ETL

Supported Databases:

- MySQL
- PostgreSQL
- SQL Server
- MongoDB

Java 21
Python 3.12+
Jenkins
Git

-----------------------
for testing:--
pipeline {
 
 
agent any
 
environment {

    PROJECT_ROOT = "${WORKSPACE}"

}
 
stages {
 
    stage('Checkout') {

        steps {

            git branch: 'main',

                url: 'https://github.com/niteshquantum/DataPlatform-Automation.git'

        }

    }
 
    stage('Set Permissions') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh '''

                pwd

                ls -la

                chmod +x scripts/bash/common/*.sh

                chmod +x scripts/bash/mysql/*.sh

                '''

            }

        }

    }
 
    stage('Validate Python Runtime') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/common/validate_python_runtime.sh'

            }

        }

    }
 
    stage('Validate Java Runtime') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/common/validate_java_runtime.sh'

            }

        }

    }
 
    stage('Install Tools') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/common/install_tools.sh'

            }

        }

    }
 
    stage('Install MySQL') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/mysql/install_mysql.sh'

            }

        }

    }
 
    stage('Start MySQL') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/mysql/start_mysql.sh'

            }

        }

    }
 
    stage('Create Database') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/mysql/create_database.sh'

            }

        }

    }
 
    stage('Run Liquibase') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/mysql/run_liquibase.sh'

            }

        }

    }
 
    stage('Validate Environment') {

        steps {

            dir("${PROJECT_ROOT}") {

                sh './scripts/bash/mysql/validate_environment.sh'

            }

        }

    }

}
 
post {
 
    success {

        echo 'UBUNTU MYSQL SETUP SUCCESSFUL'

    }
 
    failure {

        echo 'UBUNTU MYSQL SETUP FAILED'

    }
 
    always {

        echo 'UBUNTU MYSQL SETUP PIPELINE COMPLETED'

    }

}

-------------------
pipeline {

agent any

environment {
    PROJECT_ROOT = "${WORKSPACE}"
}

stages {

    stage('Checkout') {
        steps {
            git branch: 'main',
                url: 'https://github.com/niteshquantum/DataPlatform-Automation.git'
        }
    }

    stage('Set Permissions') {
        steps {
            dir("${PROJECT_ROOT}") {
                sh '''
                pwd
                ls -la
                chmod +x scripts/bash/common/*.sh
                chmod +x scripts/bash/mysql/*.sh
                '''
            }
        }
    }

   stage('Validate MySQL') {
    steps {
        dir("${PROJECT_ROOT}") {
            sh './scripts/bash/mysql/validate_mysql.sh'
        }
    }
}

    stage('Load Data') {
        steps {
            dir("${PROJECT_ROOT}") {
                sh './scripts/bash/mysql/load_data.sh'
            }
        }
    }

    
}

post {

    success {
        echo 'UBUNTU MYSQL LOAD SUCCESSFUL'
    }

    failure {
        echo 'UBUNTU MYSQL LOAD FAILED'
    }

    always {
        echo 'UBUNTU MYSQL LOAD PIPELINE COMPLETED'
    }
}


}

 
 
}

 
