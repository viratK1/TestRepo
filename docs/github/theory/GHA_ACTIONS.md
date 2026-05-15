# GitHub Actions: Complete Guide for Embedded Developers

GitHub Actions is GitHub's built-in automation system. It runs scripts automatically in response to events (like PR creation) on GitHub's servers.

> **Note**: This guide uses example scenarios. Replace `EXAMPLE_WORKFLOW_NAME`, `EXAMPLE_JOB_NAME`, and other placeholders with your actual workflow/job names.

---

## Quick Analogy

**Without GitHub Actions:**
```
You: Make code changes
Developer 1: Manually tests on Windows
Developer 2: Manually tests on Linux
Developer 3: Manually checks code style
= Slow, error-prone, human-dependent
```

**With GitHub Actions:**
```
You: Make code changes and push
GitHub: Automatically runs all tests in parallel
= Fast, consistent, no human effort
```

---

## Architecture: Where Things Run

```mermaid
graph TD
    subgraph YourComputer["YOUR COMPUTER"]
        A["git clone<br/>git checkout -b feature/my-feature<br/>Edit files<br/>git add . & git commit<br/>git push origin feature/my-feature"]
    end
    
    subgraph GitHubServers["GITHUB.COM SERVERS"]
        B["GitHub receives push<br/>Detects: PR to TARGET_BRANCH<br/>Triggers Workflow<br/>EXAMPLE_WORKFLOW_NAME"]
    end
    
    subgraph RunnerVM["GITHUB ACTIONS RUNNER<br/>Temporary Linux VM"]
        C["Step 1: Checkout code<br/>git clone & checkout"]
        D["Step 2: Run script<br/>bash scripts/EXAMPLE_SCRIPT.sh"]
        E["Step 3: Report result<br/>PASS or FAIL"]
        C --> D --> E
    end
    
    subgraph PRStatus["YOUR PR ON GITHUB"]
        F["PR #42: EXAMPLE_FEATURE_DESCRIPTION<br/><br/>Status Checks:<br/>EXAMPLE_JOB_NAME: PASSED<br/><br/>Merge button: ENABLED"]
    end
    
    A -->|Push| B
    B -->|Trigger| RunnerVM
    E -->|Report back| F
    
    style YourComputer fill:#e1f5ff
    style GitHubServers fill:#fff3e0
    style RunnerVM fill:#f3e5f5
    style PRStatus fill:#e8f5e9
```

---

## The Workflow File

Your workflow file: `.github/workflows/EXAMPLE_WORKFLOW_NAME.yml`

```yaml
name: EXAMPLE_WORKFLOW_NAME                      # Human-readable name

on:
  pull_request:
    branches:
      - TARGET_BRANCH                           # Only run on PRs to this branch
    types:
      - opened                                  # Trigger on these events:
      - reopened
      - synchronize                             # (new commits pushed)
      - ready_for_review                        # (marked ready from draft)

jobs:
  EXAMPLE_JOB_NAME:                             # Job name
    if: github.event.pull_request.draft == false  # Skip draft PRs
    runs-on: ubuntu-latest                      # Run on Linux server

    steps:
      - name: Check out repository              # Step 1: Get code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0                        # Get full history

      - name: Run validation                    # Step 2: Run script
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
        run: bash scripts/EXAMPLE_SCRIPT.sh "$BASE_SHA"
```

---

## Workflow Execution Flow

```mermaid
graph TD
    A["Developer pushes branch<br/>to GitHub"] --> B["GitHub detects event<br/>pull_request: opened"]
    B --> C{"Check: Is PR<br/>a draft?"}
    
    C -->|Yes| D["Skip workflow<br/>Developer can work<br/>freely"]
    C -->|No| E["Start runner<br/>GitHub spins up<br/>Linux VM"]
    
    E --> F["Step 1: Checkout<br/>git clone repo<br/>git checkout branch"]
    F --> G["Step 2: Run script<br/>bash scripts/<br/>EXAMPLE_SCRIPT.sh"]
    
    G --> H{"Validation<br/>passed?"}
    H -->|Yes| I["Exit code: 0<br/>SUCCESS"]
    H -->|No| J["Exit code: 1<br/>FAILURE"]
    
    I --> K["Status check: PASS<br/>shown on PR"]
    J --> L["Status check: FAIL<br/>shown on PR"]
    
    K --> M["Merge button<br/>ENABLED"]
    L --> N["Merge button<br/>DISABLED"]
    
    N --> O["Developer must<br/>fix issue"]
    O --> P["git push again"]
    P --> E
```

---

## Where Code Actually Runs

### Your Computer (Local)
```bash
# You run these commands:
$ git checkout -b feature/EXAMPLE_FEATURE_NAME
$ vim PATH_TO_CONFIG_FILE  # Example: Edit your config file
$ git add .
$ git commit -m "EXAMPLE_COMMIT_MESSAGE"
$ git push origin feature/EXAMPLE_FEATURE_NAME
↑ Everything runs on YOUR machine
```

### GitHub's Servers
```
Your push arrives → GitHub detects it
↓
Searches: .github/workflows/*.yml files
↓
Finds: EXAMPLE_WORKFLOW_NAME.yml
↓
"A PR to TARGET_BRANCH was created → trigger this workflow"
```

### GitHub Actions Runner (Temporary Linux VM)
```bash
# GitHub spins up a Linux machine (ubuntu-latest)
# Runs these steps automatically:

Step 1: actions/checkout@v4
  $ git clone https://github.com/your-org/your-repo.git
  $ cd your-repo
  $ git checkout your-branch

Step 2: Custom script
  $ bash scripts/EXAMPLE_SCRIPT.sh <base-sha>
  
  Inside script:
    - Extract data from your branch
    - Compare with TARGET_BRANCH
    - Validate against requirements
    - Output result
    - Exit with code 0 (pass) or 1 (fail)

Step 3: Report back to GitHub
  GitHub records: "Job passed" or "Job failed"
  Updates PR status checks
```

After job finishes, runner is destroyed. No resources used if job not running.

---

## Complete Data Flow

```mermaid
sequenceDiagram
    actor Dev as Developer
    participant Local as Local Computer
    participant GitHub as GitHub.com
    participant Runner as Runner VM
    participant PR as PR Status

    Dev->>Local: git push feature/EXAMPLE_FEATURE
    Local->>GitHub: Send commits & branch ref
    
    GitHub->>GitHub: Read .github/workflows/EXAMPLE_WORKFLOW_NAME.yml
    GitHub->>GitHub: Check trigger events (pull_request, opened, etc)
    GitHub->>GitHub: Webhook: PR #42 created to TARGET_BRANCH
    
    GitHub->>Runner: Allocate new Linux VM
    Runner->>Runner: Step 1: checkout repo
    Runner->>GitHub: git clone <repo>
    GitHub->>Runner: Send repo files
    
    Runner->>Runner: Step 2: run script
    Runner->>Runner: Extract data
    Runner->>Runner: Compare and validate
    
    Runner->>GitHub: Exit code 0 (PASS)
    
    GitHub->>GitHub: Status check complete
    GitHub->>PR: Update: "EXAMPLE_JOB_NAME: PASS"
    
    PR->>Dev: Notification: Check passed!
    Dev->>PR: Click Merge button
    Dev->>GitHub: Merge PR
    GitHub->>GitHub: Fast-forward TARGET_BRANCH
```

---

## Runner Anatomy

A GitHub Actions "runner" is essentially:

```mermaid
graph TB
    subgraph VM["TEMPORARY LINUX VIRTUAL MACHINE<br/>Created when job starts<br/>Destroyed when job ends"]
        OS["Ubuntu 22.04 LTS"]
        TOOLS["Pre-installed tools:<br/>• Git<br/>• Bash shell<br/>• Python, Node, Docker<br/>• curl, wget, etc"]
        SPECS["Specs:<br/>• 2 vCPU cores<br/>• 7 GB RAM<br/>• 14 GB disk space<br/>• Network access to GitHub"]
        OS --> TOOLS
        OS --> SPECS
    end
    
    subgraph WORKDIR["Working Directory"]
        PATH["/home/runner/work/TestRepo/TestRepo"]
        FILES["Your repo files:<br/>.git/<br/>.github/<br/>app_controller/<br/>scripts/"]
        PATH --> FILES
    end
    
    VM --> WORKDIR
    
    style VM fill:#f3e5f5
    style WORKDIR fill:#e1f5ff
```

When a job runs:

```bash
# Job starts
runner$ pwd
/home/runner/work/TestRepo/TestRepo

# Code is checked out
runner$ ls -la
.git/
.github/
app_controller/
scripts/
...

# Your script runs
runner$ bash scripts/check_build_ver_bump.sh abc123
[checking version bump...]
[PASS] At least one version was incremented

# Job ends
# Runner is terminated
```

---

## Environment Variables & Secrets

The workflow can access GitHub context:

```yaml
steps:
  - name: Access PR information
    run: |
      echo "PR #: ${{ github.event.pull_request.number }}"
      echo "Base branch: ${{ github.event.pull_request.base.ref }}"
      echo "Head branch: ${{ github.event.pull_request.head.ref }}"
      echo "Base SHA: ${{ github.event.pull_request.base.sha }}"
      echo "Author: ${{ github.event.pull_request.user.login }}"
```

In your workflow:

```yaml
env:
  BASE_SHA: ${{ github.event.pull_request.base.sha }}

steps:
  - name: Run check
    run: bash scripts/check_build_ver_bump.sh "$BASE_SHA"
    # BASE_SHA is passed to the script
```

---

## What Happens at Each Event

```mermaid
graph TD
    A["Developer creates<br/>pull_request"] -->|Event: opened| B["Workflow triggers<br/>EXAMPLE_JOB_NAME starts"]
    C["Developer pushes<br/>new commits"] -->|Event: synchronize| B
    D["Developer reopens<br/>closed PR"] -->|Event: reopened| B
    E["Developer marks<br/>PR ready from draft"] -->|Event: ready_for_review| B
    
    B --> F["Runner VM spins up"]
    F --> G["Runs validation"]
    G --> H["Reports result to PR"]
    
    I["PR stays in draft<br/>no changes"] -->|NO Event| J["Workflow skipped<br/>if: draft == false"]
```

---

## Multiple Runners (Parallelization)

If you had multiple jobs, they could run in parallel:

```yaml
jobs:
  check-build-ver:
    runs-on: ubuntu-latest
    steps:
      - run: bash scripts/check_build_ver_bump.sh

  test-compilation:
    runs-on: ubuntu-latest
    steps:
      - run: make build

  lint-code:
    runs-on: ubuntu-latest
    steps:
      - run: pylint src/
```

This would spin up THREE runners simultaneously:

```mermaid
gantt
    title GitHub Actions Parallel Job Execution
    dateFormat YYYY-MM-DD HH:mm:ss
    
    section Jobs
    check-build-ver :job1, 2026-05-14 10:00:00, 30s
    test-compilation :job2, 2026-05-14 10:00:00, 60s
    lint-code :job3, 2026-05-14 10:00:00, 15s
```

All run at same time, results collected.

---

## Viewing Workflow Execution

On GitHub PR page:

```
PR #42: Add temperature calibration

Checks (1 completed)
├─ Enforce build_ver bump
   └─ check-build-ver
      Status: PASSED
      Duration: 2m 3s
      
      Logs:
      ├─ Check out repository (5s)
      ├─ Require build_ver change (10s)
      └─ [PASS] At least one version was incremented
```

You can click to see full logs from runner.

---

## Cost Implications

**For public repos:** GitHub Actions is FREE
- Unlimited minutes per month
- No credit card required

**For private repos:** 
- 2,000 free minutes/month (included with account)
- Each additional 1,000 minutes = $0.24

**Your usage:** 
- Each run takes ~30 seconds
- ~1.5 minutes per day if 3 PRs
- Well within free tier

---

## Troubleshooting Workflows

### Problem: Workflow not triggering

**Cause**: Workflow file has syntax error

**Check**:
```bash
# Verify file exists and format is valid
cat .github/workflows/EXAMPLE_WORKFLOW_NAME.yml

# Check in GitHub UI: Settings → Actions → Workflows
# If syntax error, it won't appear
```

### Problem: Script fails but shouldn't

**Check logs**:
1. Go to PR page
2. Click "Details" on failed check
3. See full runner output
4. Look for error messages

### Problem: Can't see status check on PR

**Cause**: Workflow hasn't run yet

**Fix**:
1. Verify workflow file exists: `.github/workflows/EXAMPLE_WORKFLOW_NAME.yml`
2. Create NEW PR to `TARGET_BRANCH`
3. Workflow triggers automatically
4. After first run, appears in branch protection options

---

## Workflow Execution Simplified

```mermaid
graph LR
    A["You edit<br/>files"] --> B["git push"]
    B --> C["GitHub detects<br/>PR to TARGET_BRANCH"]
    C --> D["Workflow triggers<br/>on: pull_request"]
    D --> E["Runner VM<br/>spins up"]
    E --> F["checkout repo<br/>git clone"]
    F --> G["Run script<br/>EXAMPLE_SCRIPT.sh"]
    G --> H{"Validation<br/>passed?"}
    H -->|Yes| I["Exit 0<br/>SUCCESS"]
    H -->|No| J["Exit 1<br/>FAIL"]
    I --> K["Status: PASS"]
    J --> L["Status: FAIL"]
    K --> M["Merge button<br/>enabled"]
    L --> N["Merge button<br/>disabled"]
```

---

## Key Takeaways for Embedded Developers

1. **GitHub Actions = Automation in the cloud**
   - You push code
   - GitHub runs scripts automatically
   - Reports results back on PR

2. **Runs on temporary Linux VMs**
   - Spun up on-demand
   - Destroyed after job ends
   - Isolated environment

3. **No manual work needed**
   - Script runs same way every time
   - Consistent results
   - Catches issues before merge

4. **Workflows live in `.github/workflows/`**
   - YAML format (easy to read)
   - Triggered by events (PR, push, schedule, etc)
   - Can run shell scripts, docker, etc

5. **Integrated with branch protection**
   - Failing check blocks merge
   - Prevents non-compliant code from reaching `TARGET_BRANCH`
   - Enforces quality standards

---

## How to Adapt This Guide

- Replace `EXAMPLE_WORKFLOW_NAME` with your actual workflow name
- Replace `EXAMPLE_JOB_NAME` with your job name
- Replace `EXAMPLE_SCRIPT.sh` with your script name
- Replace `TARGET_BRANCH` with your integration branch (develop, main, etc)
- Replace other EXAMPLE_* placeholders with your specific content
