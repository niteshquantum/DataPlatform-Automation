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


        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/mysql/setup/validate_python_requirements.sh'
            }
        }

        stage('Start MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/start_mysql.sh'
            }
        }

        stage('Validate MySQL') {
            steps {
                sh './scripts/bash/mysql/setup/validate_mysql.sh'
            }
        }


        stage('Download Dataset') {
            steps {
                sh './scripts/bash/common/download_dataset.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/mysql/load/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/mysql/load/validate_loaded_data.sh'
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
