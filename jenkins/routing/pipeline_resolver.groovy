def resolve(String database, String action, String operatingSystem) {

    def normalizedDatabase = database.toLowerCase()
    def normalizedAction = action.toLowerCase()
    def normalizedOs = operatingSystem.toLowerCase()

    def agentLabel = normalizedOs == 'windows' ? 'windows-node' : 'ubuntu-node'

    def pipelinePath = "jenkins/${normalizedDatabase}/${normalizedOs}/${normalizedAction}_pipeline.groovy"

    return [
        database      : normalizedDatabase,
        action        : normalizedAction,
        operatingSystem: normalizedOs,
        agentLabel    : agentLabel,
        pipelinePath  : pipelinePath
    ]
}
