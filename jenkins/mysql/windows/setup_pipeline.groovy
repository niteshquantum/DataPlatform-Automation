pipeline {

    agent any

    options {
        disableConcurrentBuilds()
    }

    stages {

        stage('Check Administrator Privileges') {
            steps {
                script {

                    def adminStatus = bat(
                        script: 'scripts\\batch\\common\\check_admin_privileges.bat',
                        returnStatus: true
                    )

                    if (adminStatus == 0) {

                        writeFile file: 'admin_status.txt', text: 'true'

                        echo 'Administrator privileges available.'
                        echo 'MySQL Service and Global MySQL configuration will be enabled.'

                    } else {

                        writeFile file: 'admin_status.txt', text: 'false'

                        echo 'Administrator privileges not available.'
                        echo 'MySQL Service and Global MySQL configuration will be skipped.'
                        echo 'MySQL will run using project-local mode.'
                    }

                    def adminResult = readFile('admin_status.txt').trim()

                    echo "ADMIN STATUS = ${adminResult}"
                }
            }
        }

        stage('Validate Python Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_python_runtime.bat'
            }
        }

        stage('Install Python Requirements') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\install_python_requirements.bat'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_python_requirements.bat'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                bat 'scripts\\batch\\common\\validate_java_runtime.bat'
            }
        }

        stage('Install Tools') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\install_tools.bat'
            }
        }

        stage('Deploy MySQL') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\deploy_mysql.bat'
            }
        }

        stage('Configure MySQL Service') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {

                echo 'Administrator privileges available.'
                echo 'Configuring MySQL Windows Service...'

                bat 'scripts\\batch\\mysql\\setup\\configure_mysql_service.bat'
            }
        }

        stage('Start MySQL') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() != 'true'
                }
            }

            steps {

                echo 'Administrator privileges unavailable.'
                echo 'Starting MySQL in project-local mode...'

                bat 'scripts\\batch\\mysql\\setup\\start_mysql.bat'
            }
        }

        stage('Create Database') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\create_database.bat'
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

        stage('Configure Global MySQL') {

            when {
                expression {
                    return readFile('admin_status.txt').trim() == 'true'
                }
            }

            steps {

                echo 'Administrator privileges available.'
                echo 'Configuring Global MySQL command...'

                bat 'scripts\\batch\\mysql\\setup\\configure_global_mysql.bat'
            }
        }

        stage('Validate Environment') {
            steps {
                bat 'scripts\\batch\\mysql\\setup\\validate_environment.bat'
            }
        }
    }

    post {

        success {

            echo 'MYSQL SETUP SUCCESSFUL'

            script {

                def adminResult = readFile('admin_status.txt').trim()

                if (adminResult == 'true') {

                    echo 'MySQL Windows Service configured successfully.'
                    echo 'Global MySQL configuration completed successfully.'

                } else {

                    echo 'MySQL configured successfully in project-local mode.'
                    echo 'Windows Service and Global MySQL configuration were skipped because Administrator privileges were unavailable.'
                }
            }
        }

        failure {
            echo 'MYSQL SETUP FAILED'
        }

        always {
            echo 'MYSQL SETUP PIPELINE COMPLETED'
        }
    }
}
