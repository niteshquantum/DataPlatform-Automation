pipeline {

    agent any

    stages {

        stage('Set Permissions') {
            steps {
                sh '''
                find scripts/bash -type f -name "*.sh" -exec chmod +x {} \\;
                '''
            }
        }

        stage('Validate Python Runtime') {
            steps {
                sh './scripts/bash/common/validate_python_runtime.sh'
            }
        }
        stage('Install Python Requirements') {
            steps {
                sh './scripts/bash/mysql/setup/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/mysql/setup/validate_python_requirements.sh'
            }
        }
        stage('Validate Java Runtime') {
            steps {
                sh './scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh './scripts/bash/mysql/setup/install_tools.sh'
            }
        }

        stage('Install MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/install_mysql.sh'
            }
        }

        stage('Deploy MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/deploy_mysql.sh'
            }
        }

        stage('Start MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/start_mysql.sh'
            }
        }

        stage('Create Database') {
            steps {
                sh './scripts/bash/mysql/setup/create_database.sh'
            }
        }

        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/mysql/setup/run_liquibase.sh'
            }
        }

        stage('Deploy Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/mysql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Validate Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/mysql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/validate_objects.sh'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Deploy Functions') {
            steps {
                script {
                    def functionsDir = new File('liquibase/mysql/objects/functions')
                    if (functionsDir.exists() && functionsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Validate Functions') {
            steps {
                script {
                    def functionsDir = new File('liquibase/mysql/objects/functions')
                    if (functionsDir.exists() && functionsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/validate_objects.sh'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                script {
                    def proceduresDir = new File('liquibase/mysql/objects/procedures')
                    if (proceduresDir.exists() && proceduresDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                script {
                    def proceduresDir = new File('liquibase/mysql/objects/procedures')
                    if (proceduresDir.exists() && proceduresDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/validate_objects.sh'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Deploy Triggers') {
            steps {
                script {
                    def triggersDir = new File('liquibase/mysql/objects/triggers')
                    if (triggersDir.exists() && triggersDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }

        stage('Validate Triggers') {
            steps {
                script {
                    def triggersDir = new File('liquibase/mysql/objects/triggers')
                    if (triggersDir.exists() && triggersDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/mysql/objects/validate_objects.sh'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }

        stage('Configure Global MySQL') {
    steps {
        sh 'bash ./scripts/bash/mysql/setup/configure_global_mysql.sh'
    }
}
        stage('Validate Environment') {
            steps {
                sh './scripts/bash/mysql/setup/validate_environment.sh'
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
}
