# 🏥 Public-Sector Talent Acquisition Analytics (R)

[![R](https://img.shields.io/badge/R-4.x-276DC3?logo=r)](https://r-project.org)
[![Shiny](https://img.shields.io/badge/Shiny-Dashboard-4C72B0)](https://shiny.posit.co)
[![Live Demo](https://img.shields.io/badge/🚀_Live_Demo-shinyapps.io-blue)](https://jarvissimms12.shinyapps.io/dohmh-talent)

> **Data note:** all 1,400 requisitions, applicants and EEO records in this project are **simulated** (`set.seed(42)` in `analysis.R`). Department names are modeled on DOHMH's structure, but nothing here is real DOHMH data or reflects its actual hiring. For analysis of **real** NYC government job postings and payroll, see [state-of-nyc](https://github.com/jarvissimms12/state-of-nyc).

Talent acquisition analytics platform built entirely in **R**, designed around the duties listed in the NYC DOHMH Talent Acquisition Data Analyst job posting (March 2026). Simulates 1,400 requisitions across 10 departments to produce all the recurring reports described in the role — time-to-fill, source utilization, applicant flow, offer acceptance rates, EEO adverse impact ratios, and workforce gap identification.

---

## 🚀 How to Run

```r
# 1. Install all packages (run once)
source("install.R")

# 2. Run the full analysis pipeline
Rscript analysis.R

# 3. Launch the Shiny dashboard
shiny::runApp("dashboard.R")
```

---

## 📋 Direct Mapping to DOHMH Job Duties

| Job Description Duty | This Project |
|---|---|
| "Time-to-fill, time-to-hire, vacancy rates" | TTF Analysis tab — by dept, level, quarter trend |
| "Applicant flow, source utilization" | Source Utilization tab — vol, hire rate, retention |
| "Offer acceptance rates" | Overview KPI + offer acceptance by level chart |
| "ATS data monitoring (NYCAPS/SmartRecruiter)" | ATS Data Explorer tab — full filterable table |
| "Applicant flow data to support DEI initiatives" | EEO tab — adverse impact ratios by race/ethnicity |
| "Documentation for audits and regulatory reviews" | EEO 4/5ths rule table with flag column |
| "Identify trends, workforce gaps, bottlenecks" | Recommendations tab — data-driven action items |
| "Process efficiency; recommend improvements" | Recommendations tab — 5 specific actions |

---

## 🖥️ Dashboard Tabs

| Tab | What It Shows |
|-----|---------------|
| **Recruitment Overview** | 6 KPIs, TTF by dept, offer acceptance, quarterly trend, retention |
| **Hiring Pipeline Funnel** | Applicant → Screened → Interviewed → Offered → Accepted → Hired |
| **Source Utilization** | Volume + hire rate + retention by source (Indeed, LinkedIn, Referral, etc.) |
| **Time-to-Fill Analysis** | Distribution histogram, departments over 60-day target |
| **EEO / DEI Compliance** | Adverse impact ratio chart, applicant flow by race + gender |
| **Recommendations** | 5 data-driven process improvement recommendations |
| **ATS Data Explorer** | Full filterable requisition table |

---

## 🛠️ R Packages

`tidyverse` · `ggplot2` · `lubridate` · `shiny` · `shinydashboard` · `plotly` · `DT` · `scales` · `gridExtra`

---

## 🌐 Deploy to shinyapps.io (free)

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name="jarvissimms12", token="YOUR_TOKEN", secret="YOUR_SECRET")
rsconnect::deployApp()
```

---

## 👤 Author

**Jarvis Simms** | MS Data Science, NYIT 2025 | Brooklyn, NY  
[GitHub](https://github.com/jarvissimms12)
