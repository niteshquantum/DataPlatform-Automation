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
                bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Start MySQL Service') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
            }
        }

        stage('Validate MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_mysql.bat'
            }
        }


        stage('Download Dataset') {
            steps {
                bat 'scripts\\batch\\common\\download_dataset.bat'
            }
        }

        stage('Validate CSV') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\validate_csv.bat'
            }
        }

        stage('Load Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\load_data.bat'
            }
        }

        stage('Validate Loaded Data') {
            steps {
                bat 'scripts\\batch\\mysql\\load\\validate_loaded_data.bat'
            }
        }

        stage('Deploy Views') {
            steps {
                script {
                    def viewsDir = new File('liquibase/mysql/objects/views')
                    if (viewsDir.exists() && viewsDir.listFiles()?.any { it.name.endsWith('.xml') }) {
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\deploy_objects.bat'
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
                        bat 'scripts\\batch\\mysql\\objects\\validate_objects.bat'
                    } else {
                        echo 'No Triggers declared.'
                    }
                }
            }
        }
    }

    post {

        success {
            echo 'MYSQL LOAD SUCCESSFUL'
        }

        failure {
            echo 'MYSQL LOAD FAILED'
        }

        always {
            echo 'MYSQL LOAD PIPELINE COMPLETED'
        }
    }
}
