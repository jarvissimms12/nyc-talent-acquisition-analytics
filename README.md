# 🏥 Public-Sector Talent Acquisition Analytics (R)

[![R](https://img.shields.io/badge/R-4.x-276DC3?logo=r)](https://r-project.org)
[![Shiny](https://img.shields.io/badge/Shiny-Dashboard-4C72B0)](https://shiny.posit.co)
[![Live Demo](https://img.shields.io/badge/🚀_Live_Demo-shinyapps.io-blue)](https://jarvissimms12.shinyapps.io/dohmh-talent)

> **Data note:** all 1,400 requisitions, applicants and EEO records in this project are **simulated** (`set.seed(42)` in `analysis.R`). Department names are modeled on DOHMH's structure, but nothing here is real DOHMH data or reflects its actual hiring. For analysis of **real** NYC government job postings and payroll, see [state-of-nyc](https://github.com/jarvissimms12/state-of-nyc).

Talent acquisition analytics platform built entirely in **R**, designed around the duties listed in the NYC DOHMH Talent Acquisition Data Analyst job posting (March 2026). Simulates 1,400 requisitions across 10 departments to produce all the recurring reports described in the role — time-to-fill, source utilization, applicant flow, offer acceptance rates, EEO adverse impact ratios, and workforce gap identification.


## Summary

| | |
|---|---|
| **Question** | Can one R pipeline produce a public health agency's recurring talent-acquisition reports: time-to-fill, applicant funnel, source quality, offer acceptance and EEO adverse impact? |
| **Data** | 1,400 simulated requisitions across 10 departments and 147,774 applicants. Race/ethnicity is assigned **at random** in the simulation, so the true adverse impact is zero. |
| **Method** | tidyverse reporting; funnel conversion; retention by source; 4/5ths-rule adverse impact with two-proportion tests and a Holm correction; Shiny dashboard |
| **Result** | Average time-to-fill **60 days**, with 3 departments over the 60-day target (Nursing 68, Epidemiology 67, Disease Control 66). Offer acceptance **83.8%**; 12-month retention **79.6%**, highest for University Partner hires (89.2%). EEO: **0 groups flagged** for adverse impact; overall chi-square of hires by race χ² = 7.94, df = 7, **p = 0.34**. |
| **Takeaway** | The EEO result is the important one. A bug in the original code reported **6 groups** with adverse impact in data where none exists. |

**The EEO bug and fix.** In the summary step, `hired = sum(hired)` ran before
`hire_rate = mean(hired)`, so the "hire rate" was really the hire count × 100 and the
"adverse impact ratio" just tracked group size, flagging every smaller group. Fixing
the rate (hires ÷ applicants) still left 3 flags, because the 4/5ths rule compares
every group with the **luckiest** one (here "Two or More Races", 49 hires) across 7
comparisons at once. The pipeline now flags a group only when its ratio is below 0.80
**and** a two-proportion test is significant after a Holm correction, the
practical-plus-statistical standard used in compliance reviews. In a real audit,
a false adverse-impact finding is expensive in both directions. The Shiny dashboard was also
updated for current `shinydashboard` and all 24 outputs verified to render.
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
