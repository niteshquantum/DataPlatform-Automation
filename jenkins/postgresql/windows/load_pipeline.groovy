pipeline {

    agent any

    stages {

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start PostgreSQL Service') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\start_postgresql.bat'
            }
        }

        stage('Validate PostgreSQL ') {
            steps {
                bat 'scripts\\batch\\postgresql\\setup\\validate_postgresql.bat'
            }
        }

        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\postgresql\\load\\validate_loaded_data.bat'
            }
        }

        stage('Deploy Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/postgresql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\postgresql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }
    }

    post {

        success {
            echo 'POSTGRESQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'POSTGRESQL LOAD FAILED'
        }

        always {
            echo 'POSTGRESQL LOAD PIPELINE COMPLETED'
        }
    }
}