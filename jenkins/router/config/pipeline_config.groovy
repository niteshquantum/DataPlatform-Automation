def route(

        String database,

        String action

){

    switch(database){

        case "MYSQL":

            switch(action){

                case "SETUP":

                    load(

                        "jenkins/router/mysql/setup.groovy"

                    ).call()

                    break

                case "LOAD":

                    load(

                        "jenkins/router/mysql/load.groovy"

                    ).call()

                    break

                case "CLEANUP":

                    load(

                        "jenkins/router/mysql/cleanup.groovy"

                    ).call()

                    break

            }

            break

    }

}

return this