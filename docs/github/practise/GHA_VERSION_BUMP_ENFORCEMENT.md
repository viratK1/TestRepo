# Version Bump Enforcement Policy

## Overview

This document describes the automated version bump enforcement system for the mJouleARM_G4 repository. The system ensures that every pull request (PR) merging into the `develop` branch includes at least one version increment, maintaining clear version history and preventing accidental releases without version updates.

---

## Why This Matters

The project maintains two independent version numbers:
- **UI Display Version** (`build_ver` in Style.qml): Tracks display software updates
- **Controller Firmware Version** (`FW_VERSION` in version.h): Tracks embedded system firmware updates

To ensure proper release tracking, at least one version must be incremented with each significant change merged to `develop`.

---

## Version Files

### 1. UI Display Version
- **File:** `app_ui/sciton-UI/qml/components/Style.qml`
- **Property:** `build_ver`
- **Format:** `NNNN[A-Z]` (four digits + one letter, e.g., `0193C`)
- **Increment Rule:** Numeric part must increase by at least 1
- **Letter Suffix:** Ignored for validation (can be any uppercase letter)

**Valid examples:**
- `0193C` → `0194C` ✓ (numeric: 0193 → 0194)
- `0193C` → `0194A` ✓ (numeric: 0193 → 0194, letter changed)
- `0193C` → `0193D` ✗ (numeric part didn't change)

### 2. Controller Firmware Version
- **File:** `app_controller/Sciton/Inc/version.h`
- **Define:** `FW_VERSION`
- **Format:** Semantic versioning (e.g., `1.2.3`, `306`)
- **Increment Rule:** Must increase by at least 1 (major.minor.patch format)

**Valid examples:**
- `306` → `307` ✓
- `1.2.3` → `1.2.4` ✓
- `1.2.3` → `1.3.0` ✓

---

## Merge Requirements

### At Least ONE Version Must Be Bumped

**Valid merge scenarios:**

| Scenario | UI Version | Controller Version | Status |
|----------|------------|-------------------|--------|
| UI bumped | `0193C` → `0194C` | `306` → `306` | ✅ **PASS** |
| Controller bumped | `0193C` → `0193C` | `306` → `307` | ✅ **PASS** |
| Both bumped | `0193C` → `0194C` | `306` → `307` | ✅ **PASS** |

**Invalid merge scenarios:**

| Scenario | UI Version | Controller Version | Status | Reason |
|----------|------------|-------------------|--------|--------|
| Neither bumped | `0193C` → `0193C` | `306` → `306` | ❌ **FAIL** | No increment |
| UI letter-only | `0193C` → `0193D` | `306` → `306` | ❌ **FAIL** | Numeric part unchanged |
| Decremented | `0193C` → `0192C` | `306` → `306` | ❌ **FAIL** | Version went down |

---

## For Developers: Workflow

### Step 1: Create a Feature Branch
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### Step 2: Make Your Changes

### Step 3: Create a Draft PR (Recommended)

When ready to push but not ready for review:

1. Push your branch
2. Create a **Draft Pull Request** on GitHub
3. ✅ No version check runs on draft PRs
4. Continue working, push more commits freely

### Step 4: Update Versions (When Ready to Merge)

Before marking PR as ready for review, update at least one version:

**Option A: Update UI Version**
```bash
# Edit: app_ui/sciton-UI/qml/components/Style.qml
# Change: property string build_ver: "0193C"
# To:     property string build_ver: "0194C"
git add app_ui/sciton-UI/qml/components/Style.qml
```

**Option B: Update Controller Version**
```bash
# Edit: app_controller/Sciton/Inc/version.h
# Change: #define FW_VERSION "306"
# To:     #define FW_VERSION "307"
git add app_controller/Sciton/Inc/version.h
```

### Step 5: Commit and Push
```bash
git commit -m "Bump version: 0194C"
git push origin feature/my-feature
```

### Step 6: Mark Ready for Review

Click **"Mark as ready for review"** on the GitHub PR page.

**Result:**
- ✅ Enforcement script runs automatically
- Checks both version files against the `develop` branch
- Determines if at least one version was incremented
- Shows result in PR status checks

### Step 7: Address Feedback

If the check fails:
- Update the version files
- Push new commit
- Check re-runs automatically
- Once it passes, you can merge

---

## For Maintainers: Enabling Branch Protection

Once all developers have PRs updated with versions and the enforcement script is tested, enable the automated check in GitHub:

### Step 1: Access Branch Protection Settings

1. Go to your GitHub repository
2. Click **Settings** → **Branches**
3. Under "Branch protection rules", click **Add rule**
4. Enter branch name pattern: `develop`

### Step 2: Configure Required Rules

Enable the following protection rules:

#### [REQUIRED] Require status checks to pass before merging

1. Check: **Require branches to be up to date before merging**
2. Under "Status checks that are required to pass before merging", search for and select:
   - `check-build-ver` (this is the automated version bump validator)

#### [RECOMMENDED] Require pull request reviews before merging

1. Set **Number of required reviews**: 1 or more
2. Optionally: Check **Dismiss stale pull request approvals when new commits are pushed**
3. Optionally: Check **Require code review from code owners** (if using CODEOWNERS file)

#### [REQUIRED] Require conversation resolution

1. Check: **Require all conversations on code to be resolved before merging**

#### [OPTIONAL] Other Recommended Settings

- Check: **Require commits to be signed** (optional but recommended)
- Check: **Include administrators** (ensures rules apply to everyone)

### Step 3: Verify Configuration

After saving:

1. Create a test PR with **no version bump** to `develop`
2. Verify that the **check-build-ver** status check **fails**
3. Verify you **cannot merge** the PR
4. Bump a version and push an update
5. Verify the status check **passes**
6. Verify you **can merge** the PR

### Troubleshooting Setup

#### "check-build-ver" doesn't appear in status checks

**Issue**: The workflow hasn't been triggered yet.

**Solution**:
1. Ensure the workflow file exists: `.github/workflows/enforce-build-ver-bump.yml`
2. Create a test PR to `develop` (not draft)
3. The workflow will trigger automatically
4. Once it runs once, it appears in branch protection options

### Result

After enabling:
- Merge button is disabled if check fails
- Merge button is enabled only when versions are correctly bumped
- Developers must update versions before they can merge

---

## How the Enforcement Script Works

### File Location
- **Script:** `scripts/check_build_ver_bump.sh`
- **Workflow:** `.github/workflows/enforce-build-ver-bump.yml`

### Execution Flow

**1. Trigger**
- GitHub detects PR to `develop` that is not a draft
- Workflow auto-triggers on: `opened`, `reopened`, `synchronize`, `ready_for_review` events

**2. Checkout**
- Fetches repository with full history (`fetch-depth: 0`)
- Gets base commit SHA from PR metadata

**3. Version Extraction**
- Reads `build_ver` from `app_ui/sciton-UI/qml/components/Style.qml` (current branch)
- Reads `FW_VERSION` from `app_controller/Sciton/Inc/version.h` (current branch)
- Reads same files from base commit (develop branch)

**4. Numeric Comparison** (UI version only)
- Extracts numeric part: `0193C` → `0193`, `0194C` → `0194`
- Compares as decimal numbers (avoids octal interpretation)
- Checks if new numeric > old numeric (by at least 1)

**5. Version Comparison** (Controller version)
- Compares full version strings as numbers
- Checks if new > old (by at least 1)

**6. Decision**
- ✅ If UI numeric bumped OR Controller version bumped → **PASS**
- ❌ If neither bumped → **FAIL**

**7. Output**
- GitHub Actions job shows result in PR checks
- Creates summary in workflow output
- Displays clear error message if it fails

### Failure Messages

When check fails, developers see:

```
No version bump detected. 
UI numeric part: 0193 → 0193; Controller: 306 → 306

At least ONE version must be incremented:
- UI Version: increment numeric part only (e.g., 0193C → 0194C)
- Controller Version: must increment by at least 1 (e.g., 306 → 307)
```

---

## Configuration Files

### 1. PR Template
**File:** `.github/pull_request_template.md`

Shows version bump requirements whenever a PR is created. Includes:
- Which files to modify
- Examples of valid version bumps
- Reminder that the automated check will block merge if versions aren't bumped

### 2. Enforcement Workflow
**File:** `.github/workflows/enforce-build-ver-bump.yml`

GitHub Actions workflow definition:
- Triggers on PR events targeting `develop`
- Skips draft PRs (giving developers freedom to work)
- Calls the enforcement script
- Reports results back to GitHub

### 3. Enforcement Script
**File:** `scripts/check_build_ver_bump.sh`

The actual validation logic:
- Extracts versions from both branches
- Compares numeric values
- Determines if at least one incremented
- Provides detailed error messages

---

## FAQ

### Q: I pushed my PR without bumping versions. Will it be blocked?

**A:** It depends on your branch protection settings:
- **Before enabling:** The check runs and shows ❌, but you can still merge manually
- **After enabling:** The check blocks the merge button—you must update versions first

### Q: Can I use a Draft PR to skip the check?

**A:** Yes! Create a Draft PR and the check won't run. When ready for review, click "Mark as ready for review" and the check will run. By then, you should have updated your versions.

### Q: What if only the controller version changes?

**A:** ✅ That's valid—you don't need to bump the UI version if only firmware changed.

### Q: What if only the UI version changes?

**A:** ✅ That's valid—you don't need to bump the controller version if only display software changed.

### Q: Can I bump both versions?

**A:** ✅ Yes, if both were modified significantly, bumping both is recommended for clarity.

### Q: What if the letter suffix changes but numeric part doesn't (e.g., 0193C → 0193D)?

**A:** ❌ The numeric part must increase. Changing only the letter will fail the check.

### Q: How do I know what the next version should be?

**A:** Review the release notes or git history to determine if this is a patch, minor, or major bump. Generally:
- **Patch/fix:** Increment last digit (`0193` → `0194`)
- **Minor feature:** Increment middle digit or use semantic versioning
- **Major feature:** Increment major version appropriately

### Q: What if the version file can't be read?

**A:** The script exits with an error. Check:
- The file exists in the expected location
- The file is not corrupted
- You haven't moved or renamed the version files

---

## Troubleshooting

### Script fails: "Could not read build_ver"

**Cause:** Version file moved, renamed, or malformed

**Solution:**
1. Verify `app_ui/sciton-UI/qml/components/Style.qml` exists
2. Check it contains: `property string build_ver: "0193C"` (or similar)
3. Ensure no syntax errors in the QML file

### Script fails: "Could not read FW_VERSION"

**Cause:** Controller version file issue

**Solution:**
1. Verify `app_controller/Sciton/Inc/version.h` exists
2. Check it contains: `#define FW_VERSION "306"` (or similar)
3. Ensure the define statement is correctly formatted

### Check passes but shouldn't

**Possible cause:** You bumped both versions, but expected only one to bump

**Solution:** This is actually fine—bumping both is valid and sometimes clearer.

### Check runs on a Draft PR

**Cause:** PR was marked as ready for review

**Solution:** This is correct behavior. Draft PRs skip the check, but once marked ready for review, the check runs.

---

## Implementation Checklist

- [x] Version enforcement script created (`scripts/check_build_ver_bump.sh`)
- [x] GitHub Actions workflow created (`.github/workflows/enforce-build-ver-bump.yml`)
- [x] PR template updated (`.github/pull_request_template.md`)
- [ ] Branch protection rule enabled in GitHub (Settings → Branches → develop)
- [ ] Test with a sample PR to verify check works
- [ ] Communicate policy to team

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Semantic Versioning](https://semver.org/)

---

## Questions or Issues?

If the enforcement script fails unexpectedly or you have questions about versioning policy, check:
1. The `.github/workflows/enforce-build-ver-bump.yml` workflow logs
2. The PR status checks details
3. This documentation
4. Contact the repository maintainers
