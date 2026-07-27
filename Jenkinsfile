pipeline {

    agent any

    parameters {

        choice(
            name: 'DATABASE',
            choices: ['MYSQL']
        )

        choice(
            name: 'ACTION',
            choices: ['SETUP', 'LOAD']
        )

    }

    stages {

        stage('Route Pipeline') {

            steps {

                script {

                    if (params.DATABASE == 'MYSQL') {

                        if (params.ACTION == 'SETUP') {

                            build job: 'MySQL-Setup'

                        }

                        if (params.ACTION == 'LOAD') {

                            build job: 'MySQL-Load'

                        }

                    }

                }

            }

        }

    }

}