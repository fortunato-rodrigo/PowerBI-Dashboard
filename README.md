<span id="top"></span>

# PowerBI-Dashboard
Centralized repository for version-controlling, managing, and collaborating on Power BI dashboards and reports across the organization.

## 📊 Purpose

- Track changes to Power BI reports and data models
- Enable collaboration between data teams
- Standardize report structures and naming conventions
- Facilitate deployment processes and auditability


## 🏗️ Structure
```text
repositorios/
└── PowerBI-Dashboard/
    ├── docs/
    │   ├── GIT_WORKFLOW.md
    │   └── README.md
    ├── reports/
    │   ├── daily-sales/
    │   │   ├── daily-sales.pbip
    │   │   ├── DataModel/
    │   │   ├── Visuals/
    │   │   ├── Resources/
    │   │   └── README.md
    │   └── SalesDashboard/
    ├── .gitignore
    ├── new-dashboard.ps1
    └── README.md
```


- 📁 `docs/`: Documentation and Git workflows
- 🗂️ `reports/`: Main directory for all Power BI dashboards  
- 📁 `[dashboard_name]`: Folder for each individual dashboard project  
- 🧠 `DataModel/`: DAX measures, tables, relationships (if extracted)  
- 📊 `Visuals/`: Screenshots or documentation of key visuals  
- 📎 `Resources/`: Reference data, mockups, notes, etc. (optional)


## 🚀 Getting Started

1. Clone the repo:

   ```shell
   git clone https://github.com/fortunato-rodrigo/PowerBI-Dashboard.git
   ```
   
2. Navigate to your report folder or create a new one under `/reports/`

3. Add your Power BI files (`.pbip` preferred or `.pbix`)

4. Commit your changes:
   ```shell
   git add .
   git commit -m "Add initial Sales Dashboard"
   git push origin main
   ```

## 📚 Documentation

- [Git Workflow Guide](docs/GIT_WORKFLOW.md)

### ✅ Best Practices

Prefer `.pbip` (Power BI Project format) for easier diff and collaboration

Add a README file inside each report folder

Use meaningful commit messages

Avoid uploading sensitive data or credentials

#### 🧪 WIP / Test Projects

Use branches or the /sandbox/ folder to experiment with new ideas or test features before promoting to production.

#### 📎 Related Resources

* [Power BI Git Integration](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-git)
* [PBIP Format Overview](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview)


---

[Back to top](#top)
