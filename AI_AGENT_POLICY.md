## Additional Auto-Approved Actions

### Git Operations

Approved without asking:

- git status
- git diff
- git diff --stat
- git log
- git branch
- git checkout
- git switch
- git fetch
- git pull
- git add
- git restore
- git reset --soft
- git cherry-pick
- git commit
- git push

Only ask before:

- git reset --hard
- git clean -fd
- deleting branches
- force push
- history rewrite

---

### Runtime Execution

Approved:

- Jenkins build execution
- Local batch execution
- Local PowerShell execution
- Local Python execution
- Static validation
- Runtime validation
- Temporary tracing
- Temporary debug logging
- Temporary diagnostic files

Remove all temporary diagnostics before committing.

---

### File Modifications

Approved:

- Jenkins Groovy
- Batch files
- PowerShell
- Python
- Config files
- Templates
- Documentation

Approved:

Create

Modify

Rename

Move

Delete temporary files

Cleanup temporary logs

Cleanup temporary debug code

---

### Investigation

Approved:

Compare branches

Compare commits

Compare runtime behavior

Compare Jenkins logs

Inspect environment variables

Inspect PROJECT_ROOT

Inspect PATH

Inspect ERRORLEVEL

Inspect wrappers

Inspect relative paths

Inspect configuration loading

Inspect exit code propagation

Trace complete execution flow

Instrument code temporarily

Remove instrumentation before commit

---

### Validation

Always perform:

Static validation

↓

Runtime validation

↓

Regression validation

↓

Repository consistency validation

↓

Commit

↓

Push

↓

Working tree clean

Do not stop after one successful fix.

Continue until the assigned milestone is complete.

---

### Branch Management

Approved:

Create feature branches

Switch branches

Cherry-pick validated commits

Merge only when explicitly requested.

Never merge automatically.

---

### Commit Policy

Commit only validated work.

Never commit speculative fixes.

Never leave the repository in a dirty state.

Every completed milestone must end with:

Commit

↓

Push

↓

Working tree clean

---

### Escalation

Only interrupt the user if:

- Data loss is possible
- Destructive Git operation is required
- Credentials are required
- Administrator permission outside the repository is required
- The requested action cannot be automated

Otherwise continue autonomously.