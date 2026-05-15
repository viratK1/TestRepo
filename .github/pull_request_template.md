## REQUIRED before merge to develop

> **Automated enforcement active**: The `check-build-ver` status check will validate these requirements automatically. PRs must pass this check to merge.

### Version Bump Checklist

**At least ONE version MUST be incremented:**

#### Option A: Bump UI Version
- [ ] Increment `build_ver` in [`app_ui/sciton-UI/qml/components/Style.qml`](../../app_ui/sciton-UI/qml/components/Style.qml)
- [ ] Format: `NNNN[A-Z]` with numeric part increasing (e.g., `0193C` → `0194C`)
- [ ] The letter suffix can be any uppercase letter and doesn't affect validation

#### Option B: Bump Controller Version  
- [ ] Increment `FW_VERSION` in [`app_controller/Sciton/Inc/version.h`](../../app_controller/Sciton/Inc/version.h)
- [ ] Version must increase numerically (e.g., `306` → `307` or `1.2.3` → `1.2.4`)
- [ ] Follows semantic versioning

#### Option C: Bump Both (Recommended for major changes)
- [ ] Both UI and Controller versions incremented
- [ ] Ensures clear tracking of all changes

### Examples

| Scenario | Result | Why |
|----------|--------|-----|
| `0193C` -> `0194C` | PASS | Numeric part increased |
| `306` -> `307` | PASS | Version increased |
| `0193C` -> `0194A` | PASS | Numeric part increased, letter changed |
| `0193C` -> `0193D` | FAIL | Numeric part unchanged |
| `306` -> `305` | FAIL | Version decreased |
| (no changes) | FAIL | No version bump |

### Tips

- **Draft PRs**: Version checks are skipped on draft PRs, so you can work freely
- **Ready for Review**: When you mark a draft PR as ready for review, the check will run
- **Local Testing**: Run `bash scripts/check_build_ver_bump.sh origin/develop..HEAD` to test locally
- **Questions?**: See [GITHUB_ENFORCEMENT_SETUP.md](../../GITHUB_ENFORCEMENT_SETUP.md) for detailed documentation