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
                sh './scripts/bash/postgresql/setup/install_python_requirements.sh'
            }
        }

        stage('Validate Python Requirements') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_python_requirements.sh'
            }
        }

        stage('Validate Java Runtime') {
            steps {
                sh './scripts/bash/common/validate_java_runtime.sh'
            }
        }

        stage('Install Tools') {
            steps {
                sh './scripts/bash/postgresql/setup/install_tools.sh'
            }
        }

        stage('Deploy PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/deploy_postgresql.sh'
            }
        }

	stage('Install PostgreSQL') {
	    steps {
	        sh './scripts/bash/postgresql/setup/install_postgresql.sh'
	    }
	}

        stage('Start PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/start_postgresql.sh'
            }
        }

	    stage('Configure PostgreSQL User') {
	        steps {
		        sh './scripts/bash/postgresql/setup/configure_postgresql.sh'
		    }
		}


	  stage('Create Database') {
            steps {
                sh './scripts/bash/postgresql/setup/create_database.sh'
            }
        }

        stage('Run Liquibase') {
            steps {
                sh './scripts/bash/postgresql/setup/run_liquibase.sh'
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

        stage('Configure Global PSQL') {
        steps {
            sh './scripts/bash/postgresql/setup/configure_global_psql.sh'
        }
        }

        stage('Validate PostgreSQL') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_postgresql.sh'
            }
        }


        stage('Validate Environment') {
            steps {
                sh './scripts/bash/postgresql/setup/validate_environment.sh'
            }
        }
    }

    post {

        success {
            echo 'UBUNTU POSTGRESQL SETUP SUCCESSFUL'
        }

        failure {
            echo 'UBUNTU POSTGRESQL SETUP FAILED'
        }

        always {
            echo 'UBUNTU POSTGRESQL SETUP PIPELINE COMPLETED'
        }
    }
}
