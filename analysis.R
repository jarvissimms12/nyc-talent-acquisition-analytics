# ============================================================
# analysis.R  —  Talent Acquisition Analytics (SYNTHETIC DATA)
# ============================================================
# NOTE: all requisition, applicant and EEO records below are SIMULATED
# (set.seed(42)). Nothing here is real DOHMH data.
#
# Built specifically around the duties listed in the DOHMH
# Talent Acquisition Data Analyst job posting (March 2026):
#
#   ✓ Time-to-fill, time-to-hire, vacancy rates
#   ✓ Applicant flow data by source (source utilization)
#   ✓ Offer acceptance rates
#   ✓ ATS (NYCAPS/SmartRecruiter) data monitoring
#   ✓ EEO / diversity equity analysis (applicant flow)
#   ✓ Bottleneck identification in the hiring pipeline
#   ✓ 12-month retention by department and source
#   ✓ Workforce gap analysis (vacancy management)
#   ✓ Process efficiency recommendations
#
# Stack: R (tidyverse, ggplot2, survival)
# Author: Jarvis Simms | github.com/jarvissimms12
# Run:    Rscript analysis.R
# Deploy: shiny::runApp("dashboard.R")
# ============================================================

library(tidyverse)
library(scales)
library(ggplot2)
library(gridExtra)
library(lubridate)

set.seed(42)
dir.create("data",   showWarnings = FALSE)
dir.create("assets", showWarnings = FALSE)

cat("================================================================\n")
cat("  Talent Acquisition Analytics  (R)  —  synthetic data\n")
cat("  Author: Jarvis Simms | github.com/jarvissimms12\n")
cat("================================================================\n\n")

theme_dohmh <- theme_minimal(base_size=11) +
  theme(
    plot.title       = element_text(face="bold", size=12, color="#1B5E20"),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(color="gray30")
  )


# ── 1. GENERATE ATS / RECRUITMENT DATA ──────────────────────
# Mirrors: NYCAPS/SmartRecruiter ATS data the role works with daily
cat("[1/5] Generating ATS / recruitment dataset...\n")
N <- 1400

DEPARTMENTS <- c(
  "Epidemiology", "Environmental Health", "Mental Health Services",
  "Bureau of Child Health", "Data Analytics", "Nursing",
  "HR/Labor Relations", "IT", "Finance", "Disease Control"
)
SOURCES <- c(
  "Indeed", "LinkedIn", "NYC.gov Jobs", "Employee Referral",
  "University Partner", "Handshake", "Diversity Job Board", "Agency/Staffing"
)
LEVELS <- c("Entry Level","Mid Level","Senior","Supervisor","Manager","Director")
TITLES <- c(
  "Public Health Analyst","Epidemiologist","Community Health Worker",
  "Registered Nurse","Data Analyst","IT Specialist","HR Coordinator",
  "Environmental Health Inspector","Mental Health Counselor","Financial Analyst"
)
EEO_RACE <- c(
  "Hispanic/Latino","Black/African American","White","Asian",
  "Two or More Races","American Indian","Native Hawaiian","Not Disclosed"
)
EEO_GENDER <- c("Female","Male","Non-Binary","Not Disclosed")

department <- sample(DEPARTMENTS, N, replace=TRUE)
source     <- sample(SOURCES, N, replace=TRUE,
               prob=c(.22,.18,.20,.12,.10,.07,.06,.05))
level      <- sample(LEVELS, N, replace=TRUE,
               prob=c(.28,.25,.20,.12,.10,.05))
title      <- sample(TITLES, N, replace=TRUE)
eeo_race   <- sample(EEO_RACE, N, replace=TRUE,
               prob=c(.28,.26,.20,.14,.05,.02,.01,.04))
eeo_gender <- sample(EEO_GENDER, N, replace=TRUE,
               prob=c(.55,.38,.03,.04))

# Date range: Jan 2024 – Feb 2026 (18 months of data)
req_open_date <- sample(
  seq(as.Date("2024-01-01"), as.Date("2026-02-01"), by="day"),
  N, replace=TRUE)

# Time-to-fill (days) — varies by level and dept
base_ttf <- case_when(
  level == "Director"   ~ rnorm(N, 95, 22),
  level == "Manager"    ~ rnorm(N, 82, 20),
  level == "Supervisor" ~ rnorm(N, 68, 18),
  level == "Senior"     ~ rnorm(N, 58, 16),
  level == "Mid Level"  ~ rnorm(N, 46, 15),
  TRUE                  ~ rnorm(N, 38, 14)
)
# Bottleneck: certain depts take longer (Epidemiology, Nursing)
dept_mult <- ifelse(department %in% c("Epidemiology","Nursing","Disease Control"), 1.25, 1.0)
time_to_fill <- round(pmax(7, pmin(200, base_ttf * dept_mult)))

# Time-to-hire (subset who were hired; slightly less than TTF)
time_to_hire <- round(pmax(5, time_to_fill * runif(N, 0.75, 0.95)))

# Pipeline funnel
applicants     <- round(pmax(5,  rlnorm(N, meanlog=4.2, sdlog=0.9)))
screened       <- round(pmax(2,  applicants * runif(N, 0.25, 0.45)))
interviewed    <- round(pmax(1,  screened   * runif(N, 0.20, 0.40)))
offers_made    <- round(pmax(1,  interviewed* runif(N, 0.25, 0.55)))
offers_accepted<- round(pmin(offers_made, pmax(0,
                   offers_made * runif(N, 0.60, 0.95))))
hired          <- as.integer(offers_accepted >= 1)

# Offer accept rate
offer_accept_rate <- round(ifelse(offers_made > 0,
                      offers_accepted / offers_made * 100, 0), 1)

# Salary
salary <- round(pmax(35000, pmin(185000, case_when(
  level == "Director"   ~ rnorm(N, 130000, 20000),
  level == "Manager"    ~ rnorm(N, 108000, 18000),
  level == "Supervisor" ~ rnorm(N, 88000,  15000),
  level == "Senior"     ~ rnorm(N, 78000,  13000),
  level == "Mid Level"  ~ rnorm(N, 65000,  11000),
  TRUE                  ~ rnorm(N, 52000,   9000)
))))

# 12-month retention — referrals and university partners retain better
retained_12mo <- as.integer(ifelse(
  source %in% c("Employee Referral","University Partner"),
  rbinom(N, 1, 0.90),
  rbinom(N, 1, 0.76)
))

# Vacancy status
vacancy_status <- sample(
  c("Filled","Active","On Hold","Cancelled"),
  N, replace=TRUE, prob=c(.62,.22,.10,.06))

ats_df <- tibble(
  req_id            = sprintf("REQ-%04d", 1:N),
  department,
  title,
  source,
  level,
  eeo_race,
  eeo_gender,
  req_open_date,
  time_to_fill,
  time_to_hire,
  applicants,
  screened,
  interviewed,
  offers_made,
  offers_accepted,
  offer_accept_rate,
  hired,
  salary,
  retained_12mo,
  vacancy_status,
  req_quarter       = paste0(year(req_open_date)," Q", quarter(req_open_date))
)

write_csv(ats_df, "data/ats_data.csv")
cat(sprintf("  Requisitions    : %s\n",    scales::comma(N)))
cat(sprintf("  Avg time-to-fill: %.0f days\n", mean(time_to_fill)))
cat(sprintf("  Offer accept rate: %.1f%%\n",  mean(offer_accept_rate)))
cat(sprintf("  12-mo retention : %.1f%%\n",   mean(retained_12mo)*100))


# ── 2. RECURRING REPORTS ─────────────────────────────────────
# Mirrors: "develops, prepares, and maintains recurring statistical reports"
cat("\n[2/5] Building recurring reports...\n")

# — Time-to-fill/hire by department (key metric in job description)
ttf_dept <- ats_df %>%
  group_by(department) %>%
  summarise(
    reqs          = n(),
    avg_ttf       = round(mean(time_to_fill), 1),
    median_ttf    = round(median(time_to_fill), 1),
    avg_tth       = round(mean(time_to_hire), 1),
    vacancy_rate  = round(mean(vacancy_status == "Active") * 100, 1),
    avg_salary    = round(mean(salary)),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_ttf))

# — Source utilization report (explicit in job description)
source_report <- ats_df %>%
  group_by(source) %>%
  summarise(
    reqs              = n(),
    pct_of_total      = round(n()/N*100, 1),
    avg_applicants    = round(mean(applicants), 0),
    offer_accept_rate = round(mean(offer_accept_rate), 1),
    hired_count       = sum(hired),
    hire_rate         = round(mean(hired)*100, 1),
    retention_12mo    = round(mean(retained_12mo)*100, 1),
    avg_ttf           = round(mean(time_to_fill), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(retention_12mo))

# — Applicant funnel / conversion rates
funnel <- ats_df %>%
  summarise(
    stage_applicants  = sum(applicants),
    stage_screened    = sum(screened),
    stage_interviewed = sum(interviewed),
    stage_offered     = sum(offers_made),
    stage_accepted    = sum(offers_accepted),
    stage_hired       = sum(hired)
  ) %>%
  pivot_longer(everything(), names_to="stage", values_to="count") %>%
  mutate(
    stage  = str_remove(stage, "stage_") %>% str_to_title(),
    stage  = factor(stage, levels=c("Applicants","Screened","Interviewed",
                                     "Offered","Accepted","Hired")),
    pct_of_applicants = round(count / count[stage=="Applicants"] * 100, 1),
    conversion_from_prev = round(c(100,
      count[2]/count[1]*100, count[3]/count[2]*100,
      count[4]/count[3]*100, count[5]/count[4]*100,
      count[6]/count[5]*100), 1)
  )

# — Offer acceptance rate by level
offer_by_level <- ats_df %>%
  group_by(level) %>%
  summarise(
    reqs              = n(),
    offer_accept_rate = round(mean(offer_accept_rate), 1),
    avg_salary        = round(mean(salary)),
    .groups = "drop"
  ) %>%
  arrange(desc(offer_accept_rate))

# — Time-to-fill trend by quarter
ttf_trend <- ats_df %>%
  group_by(req_quarter) %>%
  summarise(avg_ttf = round(mean(time_to_fill), 1),
            reqs = n(), .groups="drop") %>%
  arrange(req_quarter)

write_csv(ttf_dept,      "data/ttf_by_department.csv")
write_csv(source_report, "data/source_utilization.csv")
write_csv(funnel,        "data/applicant_funnel.csv")
write_csv(offer_by_level,"data/offer_acceptance_by_level.csv")
write_csv(ttf_trend,     "data/ttf_trend.csv")

cat("  Top 3 longest time-to-fill departments:\n")
ttf_dept %>% head(3) %>%
  { cat(sprintf("    %-25s  %.0f days avg\n", .$department, .$avg_ttf)) }


# ── 3. EEO / DIVERSITY ANALYSIS ──────────────────────────────
# Mirrors: "applicant flow data to support DEI initiatives"
# and "documentation required for audits and regulatory reviews"
cat("\n[3/5] Running EEO / diversity analysis...\n")

# Applicant flow by race/ethnicity
# Selection rate = hires / applicants. (Computed from n_hired: writing
# `hired = sum(hired)` first and then `mean(hired)` would average the sum.)
eeo_race_flow <- ats_df %>%
  group_by(eeo_race) %>%
  summarise(
    applicants  = sum(applicants),
    n_hired     = sum(hired),
    .groups = "drop"
  ) %>%
  mutate(
    hired        = n_hired,
    hire_rate    = round(n_hired / applicants * 100, 3),
    pct_of_apps  = round(applicants / sum(applicants) * 100, 1),
    pct_of_hires = round(n_hired / sum(n_hired) * 100, 1)
  ) %>%
  select(-n_hired) %>%
  arrange(desc(applicants))

# Gender flow
eeo_gender_flow <- ats_df %>%
  group_by(eeo_gender) %>%
  summarise(applicants = sum(applicants), n_hired = sum(hired), .groups = "drop") %>%
  mutate(hired = n_hired, hire_rate = round(n_hired / applicants * 100, 3)) %>%
  select(-n_hired)

# Adverse impact: Uniform Guidelines (29 CFR 1607.4D) 4/5ths rule.
# Each group's selection rate is compared with the HIGHEST group's rate.
# Two traps make the raw rule flag groups when nothing is wrong:
#   * the reference is the luckiest of 8 noisy groups (often a small one)
#   * 7 comparisons are run at once
# So a group is flagged only when the ratio is < 0.80 AND a two-proportion
# test is significant after a Holm correction for the 7 comparisons.
ref <- eeo_race_flow %>% slice_max(hire_rate, n = 1, with_ties = FALSE)
eeo_race_flow <- eeo_race_flow %>%
  rowwise() %>%
  mutate(
    adverse_impact_ratio = round(hire_rate / ref$hire_rate, 3),
    p_value = if (eeo_race == ref$eeo_race) NA_real_ else
      suppressWarnings(prop.test(c(hired, ref$hired), c(applicants, ref$applicants))$p.value),
  ) %>%
  ungroup() %>%
  mutate(
    p_holm = p.adjust(p_value, method = "holm"),
    flag_adverse_impact = !is.na(p_holm) & adverse_impact_ratio < 0.80 & p_holm < 0.05,
    reference_group = ref$eeo_race
  )

# Overall test: are hires independent of race/ethnicity at all?
eeo_chisq <- chisq.test(rbind(eeo_race_flow$hired,
                              eeo_race_flow$applicants - eeo_race_flow$hired))

write_csv(eeo_race_flow,   "data/eeo_race_flow.csv")
write_csv(eeo_gender_flow, "data/eeo_gender_flow.csv")

flagged <- sum(eeo_race_flow$flag_adverse_impact, na.rm=TRUE)
cat(sprintf("  Reference group (highest selection rate): %s, %.2f%%\n", ref$eeo_race, ref$hire_rate))
cat(sprintf("  Groups below 0.80 ratio: %d; flagged (also Holm p < 0.05): %d\n",
    sum(eeo_race_flow$adverse_impact_ratio < 0.80), flagged))
cat(sprintf("  Overall chi-square, hires x race: X2 = %.2f, df = %d, p = %.3f\n",
    eeo_chisq$statistic, eeo_chisq$parameter, eeo_chisq$p.value))


# ── 4. BOTTLENECK & GAP ANALYSIS ─────────────────────────────
# Mirrors: "identify trends, workforce gaps, bottlenecks"
cat("\n[4/5] Identifying bottlenecks and workforce gaps...\n")

# Bottleneck: where in the funnel do we lose the most candidates?
bottleneck <- funnel %>%
  filter(stage != "Applicants") %>%
  slice_min(conversion_from_prev, n=1)

# Departments with highest vacancy rates (workforce gap)
high_vacancy <- ttf_dept %>%
  filter(vacancy_rate > 15) %>%
  arrange(desc(vacancy_rate))

# Sources with poor offer acceptance
poor_accept <- source_report %>%
  filter(offer_accept_rate < mean(source_report$offer_accept_rate)) %>%
  arrange(offer_accept_rate)

# Process efficiency: depts with TTF > 60 days
slow_depts <- ttf_dept %>%
  filter(avg_ttf > 60) %>%
  mutate(days_over_target = round(avg_ttf - 60, 0))

# Summary for recommendations
recs <- tibble(
  finding = c(
    sprintf("Biggest funnel drop at '%s' stage (%.1f%% conversion)",
            bottleneck$stage, bottleneck$conversion_from_prev),
    sprintf("%d departments exceed 60-day TTF target",   nrow(slow_depts)),
    sprintf("%d groups flagged for adverse impact (ratio < 0.80 and Holm-adjusted p < 0.05)", flagged),
    sprintf("'%s' has lowest 12-mo retention (%.1f%%)",
            source_report$source[which.min(source_report$retention_12mo)],
            min(source_report$retention_12mo)),
    sprintf("'%s' and '%s' have highest retention (>88%%)",
            source_report$source[1], source_report$source[2])
  ),
  action = c(
    "Improve screening-to-interview process; add structured screening rubric",
    "Prioritize pipeline building for Epidemiology, Nursing, Disease Control",
    "Review job requirements and outreach channels for underrepresented groups",
    "Reduce reliance on Agency/Staffing; invest in direct sourcing channels",
    "Increase Employee Referral program budget and University Partner outreach"
  )
)
write_csv(recs, "data/recommendations.csv")

cat(sprintf("  Bottleneck stage       : %s (%.1f%% conversion)\n",
    bottleneck$stage, bottleneck$conversion_from_prev))
cat(sprintf("  Depts over 60-day TTF  : %d\n", nrow(slow_depts)))
cat(sprintf("  Best retention source  : %s (%.1f%%)\n",
    source_report$source[1], source_report$retention_12mo[1]))


# ── 5. VISUALIZATIONS ────────────────────────────────────────
cat("\n[5/5] Generating charts...\n")

# P1 — Time-to-fill by department
p1 <- ttf_dept %>%
  ggplot(aes(x=reorder(department, avg_ttf), y=avg_ttf,
             fill=avg_ttf > 60)) +
  geom_col(width=0.65, show.legend=FALSE) +
  geom_hline(yintercept=60, linetype="dashed", color="red", linewidth=0.8) +
  geom_text(aes(label=sprintf("%.0f d", avg_ttf)),
            hjust=-0.15, size=3.5, fontface="bold") +
  scale_fill_manual(values=c("FALSE"="#2196F3","TRUE"="#E53935")) +
  coord_flip(clip="off") +
  expand_limits(y=max(ttf_dept$avg_ttf)*1.18) +
  annotate("text", x=0.6, y=62, label="60-day\ntarget",
           color="red", size=3, hjust=0) +
  labs(title="Avg Time-to-Fill by Department (days)\n(red = exceeds 60-day target)",
       x=NULL, y="Avg Days") +
  theme_dohmh

# P2 — Applicant funnel
p2 <- funnel %>%
  ggplot(aes(x=stage, y=count, fill=stage)) +
  geom_col(width=0.65, show.legend=FALSE) +
  geom_text(aes(label=sprintf("%s\n(%.1f%%)", scales::comma(count),
                               pct_of_applicants)),
            vjust=-0.3, size=3.2, fontface="bold") +
  scale_fill_manual(values=c(
    "Applicants"="#1565C0","Screened"="#1976D2","Interviewed"="#1E88E5",
    "Offered"="#42A5F5","Accepted"="#90CAF9","Hired"="#2e7d32")) +
  scale_y_continuous(labels=scales::comma) +
  expand_limits(y=max(funnel$count)*1.15) +
  labs(title="Hiring Funnel — Applicant Flow\n(% of total applicants at each stage)",
       x=NULL, y="Count") +
  theme_dohmh

# P3 — Source utilization + retention
p3 <- source_report %>%
  ggplot(aes(x=reorder(source, retention_12mo), y=retention_12mo,
             fill=retention_12mo)) +
  geom_col(width=0.65, show.legend=FALSE) +
  geom_text(aes(label=sprintf("%.1f%%", retention_12mo)),
            hjust=-0.15, size=3.5, fontface="bold") +
  scale_fill_gradient(low="#FFCDD2", high="#1B5E20") +
  coord_flip(clip="off") +
  expand_limits(y=105) +
  labs(title="12-Month Retention by Hiring Source (%)",
       x=NULL, y="Retention (%)") +
  theme_dohmh

# P4 — EEO adverse impact
p4 <- eeo_race_flow %>%
  filter(eeo_race != "Not Disclosed") %>%
  ggplot(aes(x=reorder(eeo_race, adverse_impact_ratio),
             y=adverse_impact_ratio,
             fill=flag_adverse_impact)) +
  geom_col(width=0.65, show.legend=FALSE) +
  geom_hline(yintercept=0.80, linetype="dashed", color="red", linewidth=0.8) +
  geom_text(aes(label=round(adverse_impact_ratio,2)),
            hjust=-0.15, size=3.5, fontface="bold") +
  scale_fill_manual(values=c("FALSE"="#2e7d32","TRUE"="#E53935")) +
  coord_flip(clip="off") +
  expand_limits(y=1.6) +
  annotate("text", x=0.6, y=0.82, label="4/5ths rule\n(0.80 threshold)",
           color="red", size=3, hjust=0) +
  labs(title="EEO Adverse Impact Ratio by Race/Ethnicity\n(< 0.80 = potential adverse impact)",
       x=NULL, y="Adverse Impact Ratio") +
  theme_dohmh

# P5 — TTF trend over time
p5 <- ttf_trend %>%
  ggplot(aes(x=req_quarter, y=avg_ttf, group=1)) +
  geom_line(color="#1B5E20", linewidth=1.5) +
  geom_point(color="#1B5E20", size=3, fill="white", shape=21, stroke=2) +
  geom_hline(yintercept=60, linetype="dashed", color="red", linewidth=0.8) +
  geom_text(aes(label=sprintf("%.0f",avg_ttf)), vjust=-0.8, size=3.2) +
  labs(title="Time-to-Fill Trend by Quarter\n(target: 60 days)",
       x=NULL, y="Avg Days to Fill") +
  theme_dohmh +
  theme(axis.text.x=element_text(angle=30, hjust=1))

# P6 — Offer acceptance by level + dept vacancy
p6 <- offer_by_level %>%
  ggplot(aes(x=reorder(level, offer_accept_rate), y=offer_accept_rate,
             fill=offer_accept_rate)) +
  geom_col(width=0.65, show.legend=FALSE) +
  geom_text(aes(label=sprintf("%.1f%%", offer_accept_rate)),
            hjust=-0.15, size=3.5, fontface="bold") +
  scale_fill_gradient(low="#FFCDD2", high="#1B5E20") +
  coord_flip(clip="off") +
  expand_limits(y=105) +
  labs(title="Offer Acceptance Rate by Job Level (%)",
       x=NULL, y="Acceptance Rate (%)") +
  theme_dohmh

png("assets/dohmh_analysis.png", width=1800, height=1100, res=130)
grid.arrange(p1, p2, p3, p4, p5, p6, ncol=3,
  top=grid::textGrob(
    "NYC DOHMH — Talent Acquisition Analytics  |  Jarvis Simms · github.com/jarvissimms12",
    gp=grid::gpar(fontsize=14, fontface="bold", col="#1B5E20")))
dev.off()
cat("  Saved: assets/dohmh_analysis.png\n")

cat(sprintf("\n================================================================\n"))
cat(sprintf("  ANALYSIS COMPLETE\n"))
cat(sprintf("  Avg time-to-fill       : %.0f days\n", mean(time_to_fill)))
cat(sprintf("  Overall offer accept   : %.1f%%\n",    mean(offer_accept_rate)))
cat(sprintf("  12-mo retention        : %.1f%%\n",    mean(retained_12mo)*100))
cat(sprintf("  EEO groups flagged     : %d\n",        flagged))
cat(sprintf("  Bottleneck stage       : %s\n",        bottleneck$stage))
cat("  Run: shiny::runApp('dashboard.R')\n")
cat("================================================================\n")
