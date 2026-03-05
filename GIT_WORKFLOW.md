# Git Workflow Documentation

## Branching Strategy: Git Flow

| Branch | Purpose | Base Branch | Merge Into |
|--------|---------|-------------|------------|
| main | Production-ready code | - | - |
| develop | Integration branch | main | - |
| feature/* | New features | develop | develop |
| release/* | Release preparation | develop | main + develop |
| hotfix/* | Production bug fixes | main | main + develop |

## Rules
- Direct pushes to `main` and `develop` are prohibited.
- All changes must go through Pull Requests.
- Feature branches must be reviewed before merging.

## Design Decisions
- Git Flow is used because our microservices require stable, versioned releases.
- Protected branches enforce code review and prevent accidental direct pushes.
- Tags on main mark every production release for traceability.
