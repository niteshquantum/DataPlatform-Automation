/**
 * Adapts the preserved pipeline stage bodies to a callable scripted module.
 * The routed module owns its stage names and commands; this runtime only
 * supplies scripted equivalents for declarative structural directives.
 */
class ScriptedModuleRuntime implements Serializable {
    def steps
    def failure
    private boolean stageEnabled = true

    ScriptedModuleRuntime(def steps) {
        this.steps = steps
    }

    void execute(Closure pipelineBody) {
        configure(pipelineBody)
        pipelineBody.call()

        // Step modules do not own a declarative post block.  Surface a
        // captured stage failure to the master or standalone wrapper so its
        // existing lifecycle and failure behaviour remain authoritative.
        if (failure != null) {
            throw failure
        }
    }

    void stages(Closure body) {
        configure(body)
        body.call()
    }

    void stage(String name, Closure body) {
        if (failure != null) {
            return
        }

        steps.stage(name) {
            stageEnabled = true
            try {
                configure(body)
                body.call()
            } catch (Exception error) {
                failure = error
            }
        }
    }

    void steps(Closure body) {
        if (stageEnabled && failure == null) {
            configure(body)
            body.call()
        }
    }

    void script(Closure body) {
        if (stageEnabled && failure == null) {
            configure(body)
            body.call()
        }
    }

    void when(Closure body) {
        def condition = new Expando()
        condition.expression = { Closure expression ->
            stageEnabled = expression.call() as boolean
        }
        body.delegate = condition
        body.resolveStrategy = Closure.DELEGATE_FIRST
        body.call()
    }

    void post(Closure body) {
        def postActions = [:]
        def handler = new Expando()
        handler.success = { Closure action -> postActions.success = action }
        handler.failure = { Closure action -> postActions.failure = action }
        handler.always = { Closure action -> postActions.always = action }
        body.delegate = handler
        body.resolveStrategy = Closure.DELEGATE_FIRST
        body.call()

        if (failure == null && postActions.success != null) {
            postActions.success.call()
        }
        if (failure != null && postActions.failure != null) {
            postActions.failure.call()
        }
        if (postActions.always != null) {
            postActions.always.call()
        }
        if (failure != null) {
            throw failure
        }
    }

    private void configure(Closure body) {
        body.delegate = this
        body.resolveStrategy = Closure.DELEGATE_FIRST
    }
}

def runtime = new ScriptedModuleRuntime(this)
return [execute: { Closure body -> runtime.execute(body) }]
