# 🧠 Git Workflow Guide

This repo uses a branching strategy based on best practices:

## 🔄 Branch Types

| Type     | Naming Example               | Purpose                             |
|----------|------------------------------|-------------------------------------|
| `main`   | `main`                       | Clean, production-ready code        |
| `dev`    | `dev`                        | Integrates features before release  |
| Feature  | `feature/daily-sales`        | Add new dashboards or files         |
| Docs     | `docs/update-readme`         | Update documentation or structure   |
| Fix      | `fix/script-path-error`      | Small bugfixes                      |
| Refactor | `refactor/folder-cleanup`    | Reorganize or rename things         |

## 🛠️ Typical Flow

1. Start from `dev`:
    git checkout dev
    git pull origin dev

2. Create feature branch:
    git checkout -b feature/my-dashboard

3. Make changes, then:
    git add .
    git commit -m "Add structure for my-dashboard"
    git push -u origin feature/my-dashboard

4. Open a Pull Request to merge into `dev`

5. Merge `dev` into `main` for releases

