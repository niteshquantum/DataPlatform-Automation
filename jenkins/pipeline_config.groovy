def validate(params) {

    def validDatabases = ['MYSQL', 'POSTGRESQL', 'MONGODB', 'MSSQL']
    def validActions = ['SETUP', 'LOAD', 'CLEANUP']
    def validCleanupModes = ['PRESERVE_DATA', 'DELETE_DATA']

    if (!validDatabases.contains(params.DATABASE)) {
        error "Invalid DATABASE: ${params.DATABASE}"
    }
    if (!validActions.contains(params.ACTION)) {
        error "Invalid ACTION: ${params.ACTION}"
    }
    if (params.ACTION == 'CLEANUP' && !validCleanupModes.contains(params.CLEANUP_MODE)) {
        error "Invalid CLEANUP_MODE: ${params.CLEANUP_MODE}"
    }
}

def resolve(String database, String action) {

    def os = ''
    def nodeLabel = ''
    def scriptPath = ''
    def executable = ''

    switch (database) {
        case 'MYSQL':
            os = 'ubuntu'
            nodeLabel = 'ubuntu-node'
            if (action == 'SETUP') {
                scriptPath = 'scripts/bash/mysql/mysql_setup_pipeline.sh'
                executable = 'sh'
            } else if (action == 'LOAD') {
                scriptPath = 'scripts/bash/mysql/mysql_load_pipeline.sh'
                executable = 'sh'
            } else if (action == 'CLEANUP') {
                scriptPath = 'scripts/bash/mysql/cleanup/mysql_cleanup_pipeline.sh'
                executable = 'sh'
            }
            break
        case 'MSSQL':
            os = 'ubuntu'
            nodeLabel = 'ubuntu-node'
            if (action == 'SETUP') {
                scriptPath = 'scripts/bash/mssql/mssql_setup_pipeline.sh'
                executable = 'sh'
            } else if (action == 'LOAD') {
                scriptPath = 'scripts/bash/mssql/mssql_load_pipeline.sh'
                executable = 'sh'
            } else if (action == 'CLEANUP') {
                scriptPath = 'scripts/bash/mssql/cleanup/mssql_cleanup_pipeline.sh'
                executable = 'sh'
            }
            break
        case 'POSTGRESQL':
            os = 'windows'
            nodeLabel = 'windows-node'
            if (action == 'SETUP') {
                scriptPath = 'scripts\\batch\\postgresql\\postgresql_setup_pipeline.bat'
                executable = 'bat'
            } else if (action == 'LOAD') {
                scriptPath = 'scripts\\batch\\postgresql\\postgresql_load_pipeline.bat'
                executable = 'bat'
            } else if (action == 'CLEANUP') {
                scriptPath = 'scripts\\batch\\postgresql\\cleanup\\postgresql_cleanup_pipeline.bat'
                executable = 'bat'
            }
            break
        case 'MONGODB':
            os = 'windows'
            nodeLabel = 'windows-node'
            if (action == 'SETUP') {
                scriptPath = 'scripts\\batch\\mongodb\\mongodb_setup_pipeline.bat'
                executable = 'bat'
            } else if (action == 'LOAD') {
                scriptPath = 'scripts\\batch\\mongodb\\mongodb_load_pipeline.bat'
                executable = 'bat'
            } else if (action == 'CLEANUP') {
                scriptPath = 'scripts\\batch\\mongodb\\cleanup\\mongodb_cleanup_pipeline.bat'
                executable = 'bat'
            }
            break
    }

    return [
        database: database,
        action: action,
        os: os,
        nodeLabel: nodeLabel,
        scriptPath: scriptPath,
        executable: executable
    ]
}
