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
                sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
            }
        }

        stage('Start PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/start_postgresql.sh'
            }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_postgresql.sh'
            }
        }

        stage('Download Dataset') {
            steps {
                sh './scripts/bash/common/download_dataset.sh'
            }
        }

        stage('Load Data') {
            steps {
                sh './scripts/bash/postgresql/load/load_data.sh'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                sh './scripts/bash/postgresql/load/validate_loaded_data.sh'
            }
        }

        stage('Deploy Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/postgresql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Validate Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/postgresql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/validate_objects.sh'
                    } else {
                        echo 'No Views declared.'
                    }
                }
            }
        }

        stage('Deploy Functions') {
            steps {
                script {
                    def functionsDir = new File('liquibase/postgresql/objects/functions')
                    if (functionsDir.exists() && functionsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Validate Functions') {
            steps {
                script {
                    def functionsDir = new File('liquibase/postgresql/objects/functions')
                    if (functionsDir.exists() && functionsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/validate_objects.sh'
                    } else {
                        echo 'No Functions declared.'
                    }
                }
            }
        }

        stage('Deploy Stored Procedures') {
            steps {
                script {
                    def proceduresDir = new File('liquibase/postgresql/objects/procedures')
                    if (proceduresDir.exists() && proceduresDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Validate Stored Procedures') {
            steps {
                script {
                    def proceduresDir = new File('liquibase/postgresql/objects/procedures')
                    if (proceduresDir.exists() && proceduresDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/validate_objects.sh'
                    } else {
                        echo 'No Stored Procedures declared.'
                    }
                }
            }
        }

        stage('Deploy Triggers') {
            steps {
                script {
                    def triggersDir = new File('liquibase/postgresql/objects/triggers')
                    if (triggersDir.exists() && triggersDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/deploy_objects.sh'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }

        stage('Validate Triggers') {
            steps {
                script {
                    def triggersDir = new File('liquibase/postgresql/objects/triggers')
                    if (triggersDir.exists() && triggersDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        sh './scripts/bash/postgresql/objects/validate_objects.sh'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }
    }

    post {

        success {
            echo 'UBUNTU POSTGRESQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU POSTGRESQL LOAD FAILED'
        }

        always {
            echo 'UBUNTU POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}
