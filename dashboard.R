# ============================================================
# dashboard.R — NYC DOHMH Talent Acquisition Dashboard (Shiny)
# Run:    shiny::runApp("dashboard.R")
# Deploy: rsconnect::deployApp() → shinyapps.io
# ============================================================

library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(DT)
library(scales)

load_data <- function() list(
  ats      = read_csv("data/ats_data.csv",                show_col_types=FALSE),
  ttf_dept = read_csv("data/ttf_by_department.csv",       show_col_types=FALSE),
  sources  = read_csv("data/source_utilization.csv",      show_col_types=FALSE),
  funnel   = read_csv("data/applicant_funnel.csv",        show_col_types=FALSE),
  eeo_race = read_csv("data/eeo_race_flow.csv",           show_col_types=FALSE),
  eeo_gen  = read_csv("data/eeo_gender_flow.csv",         show_col_types=FALSE),
  offers   = read_csv("data/offer_acceptance_by_level.csv",show_col_types=FALSE),
  ttf_trend= read_csv("data/ttf_trend.csv",               show_col_types=FALSE),
  recs     = read_csv("data/recommendations.csv",         show_col_types=FALSE)
)
d <- tryCatch(load_data(), error=function(e) NULL)

ui <- dashboardPage(
  skin = "green",
  dashboardHeader(title="DOHMH Talent Analytics"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Recruitment Overview",  tabName="overview",  icon=icon("tachometer-alt")),
      menuItem("Hiring Pipeline Funnel",tabName="funnel",    icon=icon("filter")),
      menuItem("Source Utilization",    tabName="sources",   icon=icon("sitemap")),
      menuItem("Time-to-Fill Analysis", tabName="ttf",       icon=icon("clock")),
      menuItem("EEO / DEI Compliance",  tabName="eeo",       icon=icon("balance-scale")),
      menuItem("Recommendations",       tabName="recs",      icon=icon("lightbulb")),
      menuItem("ATS Data Explorer",     tabName="data",      icon=icon("table"))
    ),
    hr(),
    if (!is.null(d)) tagList(
      selectInput("flt_dept", "Department:",
        choices=c("All", sort(unique(d$ats$department))), selected="All"),
      selectInput("flt_level","Job Level:",
        choices=c("All", sort(unique(d$ats$level))), selected="All"),
      selectInput("flt_source","Hiring Source:",
        choices=c("All", sort(unique(d$ats$source))), selected="All")
    )
  ),

  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper{background:#f4faf4}
      .box{border-radius:10px}
      .small-box{border-radius:10px}
    "))),
    tabItems(

      # ── Overview ──────────────────────────────────────────
      tabItem("overview",
        if (is.null(d))
          fluidRow(box(width=12,status="danger",
            h3("Run Rscript analysis.R first, then restart.")))
        else tagList(
          fluidRow(
            valueBoxOutput("kpi_reqs",       width=2),
            valueBoxOutput("kpi_ttf",        width=2),
            valueBoxOutput("kpi_tth",        width=2),
            valueBoxOutput("kpi_accept",     width=2),
            valueBoxOutput("kpi_retention",  width=2),
            valueBoxOutput("kpi_vacancy",    width=2)
          ),
          fluidRow(
            box(width=6, title="Avg Time-to-Fill by Department",
                status="primary", solidHeader=TRUE,
                plotlyOutput("chart_ttf_dept", height="340px")),
            box(width=6, title="Offer Acceptance Rate by Level (%)",
                status="success", solidHeader=TRUE,
                plotlyOutput("chart_offer_level", height="340px"))
          ),
          fluidRow(
            box(width=6, title="Time-to-Fill Trend by Quarter",
                status="info", solidHeader=TRUE,
                plotlyOutput("chart_ttf_trend", height="280px")),
            box(width=6, title="12-Month Retention by Hiring Source",
                status="success", solidHeader=TRUE,
                plotlyOutput("chart_retention", height="280px"))
          )
        )
      ),

      # ── Funnel ────────────────────────────────────────────
      tabItem("funnel",
        fluidRow(
          box(width=8, title="Hiring Pipeline Funnel — Applicant Flow",
              status="primary", solidHeader=TRUE,
              plotlyOutput("chart_funnel", height="400px")),
          box(width=4, title="Stage Conversion Rates", status="info", solidHeader=TRUE,
              DTOutput("tbl_funnel"))
        )
      ),

      # ── Sources ───────────────────────────────────────────
      tabItem("sources",
        fluidRow(
          box(width=6, title="Source Utilization (% of Total Requisitions)",
              status="primary", solidHeader=TRUE,
              plotlyOutput("chart_source_vol", height="320px")),
          box(width=6, title="Hire Rate by Source (%)",
              status="success", solidHeader=TRUE,
              plotlyOutput("chart_hire_rate", height="320px"))
        ),
        fluidRow(
          box(width=12, title="Source Utilization Full Report", status="primary",
              DTOutput("tbl_sources"))
        )
      ),

      # ── TTF ───────────────────────────────────────────────
      tabItem("ttf",
        fluidRow(
          box(width=6, title="Time-to-Fill Distribution (All Reqs)",
              status="warning", solidHeader=TRUE,
              plotlyOutput("chart_ttf_hist", height="320px")),
          box(width=6, title="Departments Exceeding 60-Day Target",
              status="danger", solidHeader=TRUE,
              plotlyOutput("chart_ttf_over", height="320px"))
        ),
        fluidRow(
          box(width=12, title="Department TTF Summary", status="primary",
              DTOutput("tbl_ttf"))
        )
      ),

      # ── EEO ───────────────────────────────────────────────
      tabItem("eeo",
        fluidRow(
          box(width=7, title="Adverse Impact Ratio by Race/Ethnicity (EEO 4/5ths Rule)",
              status="danger", solidHeader=TRUE,
              plotlyOutput("chart_eeo_race", height="360px")),
          box(width=5, title="What is Adverse Impact?", status="info", solidHeader=TRUE,
              h4("EEO 4/5ths Rule"),
              p("The 4/5ths rule flags potential adverse impact when a group's
                hire rate is less than 80% of the highest-performing group's
                hire rate. This is a standard EEO compliance metric. Because small
                groups produce noisy ratios, a group is flagged here only when the
                ratio is below 0.80 AND a two-proportion test is significant after a
                Holm correction for testing every group at once."),
              hr(),
              p(strong("Formula:"),
                br(), "Adverse Impact Ratio = Group Hire Rate ÷ Highest Group Hire Rate"),
              hr(),
              p(strong("Regulatory context:"), " Required for EEOC, OFCCP audits,
                and NYC Civil Service reporting. The DOHMH role explicitly lists
                'applicant flow data to support DEI' and 'documentation for audits'
                as core duties.")
          )
        ),
        fluidRow(
          box(width=6, title="Applicant Flow by Race/Ethnicity",
              status="warning", solidHeader=TRUE,
              plotlyOutput("chart_eeo_flow", height="300px")),
          box(width=6, title="Applicant Flow by Gender",
              status="info", solidHeader=TRUE,
              plotlyOutput("chart_eeo_gender", height="300px"))
        ),
        fluidRow(
          box(width=12, title="EEO Race/Ethnicity Data Table", status="primary",
              DTOutput("tbl_eeo"))
        )
      ),

      # ── Recommendations ───────────────────────────────────
      tabItem("recs",
        fluidRow(
          box(width=12, title="Data-Driven Recommendations for HR Leadership",
              status="success", solidHeader=TRUE,
              p("Generated from bottleneck analysis, source effectiveness data, and EEO review."),
              DTOutput("tbl_recs"))
        )
      ),

      # ── ATS Data ──────────────────────────────────────────
      tabItem("data",
        fluidRow(
          box(width=12, title="ATS Records (NYCAPS/SmartRecruiter format)",
              status="primary",
              DTOutput("tbl_ats"))
        )
      )
    )
  )
)

server <- function(input, output, session) {
  if (is.null(d)) return()

  fats <- reactive({
    x <- d$ats
    if (input$flt_dept   != "All") x <- filter(x, department == input$flt_dept)
    if (input$flt_level  != "All") x <- filter(x, level      == input$flt_level)
    if (input$flt_source != "All") x <- filter(x, source     == input$flt_source)
    x
  })

  # ── KPIs ──────────────────────────────────────────────────
  output$kpi_reqs      <- renderValueBox(valueBox(scales::comma(nrow(fats())),       "Requisitions",     icon=icon("briefcase"),     color="green"))
  output$kpi_ttf       <- renderValueBox(valueBox(sprintf("%.0fd",mean(fats()$time_to_fill)), "Avg Time-to-Fill", icon=icon("clock"),         color="yellow"))
  output$kpi_tth       <- renderValueBox(valueBox(sprintf("%.0fd",mean(fats()$time_to_hire)), "Avg Time-to-Hire", icon=icon("user-check"),    color="olive"))
  output$kpi_accept    <- renderValueBox(valueBox(sprintf("%.1f%%",mean(fats()$offer_accept_rate)), "Offer Accept Rate", icon=icon("handshake"),    color="teal"))
  output$kpi_retention <- renderValueBox(valueBox(sprintf("%.1f%%",mean(fats()$retained_12mo)*100), "12-Mo Retention",  icon=icon("star"),          color="blue"))
  output$kpi_vacancy   <- renderValueBox(valueBox(sprintf("%.1f%%",mean(fats()$vacancy_status=="Active")*100), "Active Vacancy Rate", icon=icon("exclamation"), color="red"))

  # ── Overview charts ───────────────────────────────────────
  output$chart_ttf_dept <- renderPlotly({
    x <- fats() %>% group_by(department) %>%
      summarise(avg=mean(time_to_fill),.groups="drop") %>% arrange(avg)
    plot_ly(x, x=~avg, y=~reorder(department,avg), type="bar", orientation="h",
            marker=list(color=~ifelse(avg>60,"#E53935","#2196F3")),
            text=~sprintf("%.0fd",avg), textposition="outside") %>%
      layout(shapes=list(list(type="line",x0=60,x1=60,y0=0,y1=1,yref="paper",
                              line=list(color="red",dash="dash",width=2))),
             xaxis=list(title="Avg Days"), yaxis=list(title=""), margin=list(l=160,r=60))
  })

  output$chart_offer_level <- renderPlotly({
    x <- fats() %>% group_by(level) %>%
      summarise(rate=mean(offer_accept_rate),.groups="drop") %>% arrange(rate)
    plot_ly(x, x=~rate, y=~reorder(level,rate), type="bar", orientation="h",
            marker=list(color=~rate, colorscale=list(c(0,"#FFCDD2"),c(1,"#1B5E20"))),
            text=~sprintf("%.1f%%",rate), textposition="outside") %>%
      layout(xaxis=list(title="Acceptance Rate (%)"), yaxis=list(title=""),
             coloraxis=list(showscale=FALSE), margin=list(l=100,r=60))
  })

  output$chart_ttf_trend <- renderPlotly({
    plot_ly(d$ttf_trend, x=~req_quarter, y=~avg_ttf, type="scatter",
            mode="lines+markers+text",
            line=list(color="#1B5E20",width=2.5),
            marker=list(color="#1B5E20",size=8),
            text=~sprintf("%.0f",avg_ttf), textposition="top center") %>%
      layout(shapes=list(list(type="line",x0=0,x1=1,xref="paper",y0=60,y1=60,
                              line=list(color="red",dash="dash"))),
             xaxis=list(title=""), yaxis=list(title="Avg Days"))
  })

  output$chart_retention <- renderPlotly({
    x <- d$sources %>% arrange(retention_12mo)
    plot_ly(x, x=~retention_12mo, y=~reorder(source,retention_12mo),
            type="bar", orientation="h",
            marker=list(color=~retention_12mo,
                        colorscale=list(c(0,"#FFCDD2"),c(1,"#1B5E20"))),
            text=~sprintf("%.1f%%",retention_12mo), textposition="outside") %>%
      layout(xaxis=list(title="12-Mo Retention (%)"), yaxis=list(title=""),
             coloraxis=list(showscale=FALSE), margin=list(l=150,r=60))
  })

  # ── Funnel ────────────────────────────────────────────────
  output$chart_funnel <- renderPlotly({
    plot_ly(d$funnel, x=~stage, y=~count, type="bar",
            marker=list(color=c("#1565C0","#1976D2","#1E88E5",
                                "#42A5F5","#90CAF9","#2e7d32")),
            text=~paste0(scales::comma(count),"\n(",pct_of_applicants,"%)"),
            textposition="outside") %>%
      layout(xaxis=list(title=""), yaxis=list(title="Applicant Count"),
             margin=list(t=40,b=40))
  })
  output$tbl_funnel <- renderDT({
    d$funnel %>%
      mutate(count=scales::comma(count),
             pct_of_applicants=sprintf("%.1f%%",pct_of_applicants),
             conversion_from_prev=sprintf("%.1f%%",conversion_from_prev)) %>%
      rename(Stage=stage, Count=count,
             `% of Applicants`=pct_of_applicants,
             `Conversion from Prev`=conversion_from_prev) %>%
      datatable(rownames=FALSE, options=list(pageLength=6,dom="t"))
  })

  # ── Sources ───────────────────────────────────────────────
  output$chart_source_vol <- renderPlotly({
    plot_ly(d$sources, labels=~source, values=~reqs, type="pie",
            hole=0.45, textinfo="label+percent") %>%
      layout(showlegend=FALSE, margin=list(t=20,b=20))
  })
  output$chart_hire_rate <- renderPlotly({
    x <- d$sources %>% arrange(hire_rate)
    plot_ly(x, x=~hire_rate, y=~reorder(source,hire_rate), type="bar",
            orientation="h", marker=list(color="#1B5E20"),
            text=~sprintf("%.1f%%",hire_rate), textposition="outside") %>%
      layout(xaxis=list(title="Hire Rate (%)"), yaxis=list(title=""),
             margin=list(l=150,r=60))
  })
  output$tbl_sources <- renderDT({
    d$sources %>%
      mutate(pct_of_total=sprintf("%.1f%%",pct_of_total),
             offer_accept_rate=sprintf("%.1f%%",offer_accept_rate),
             hire_rate=sprintf("%.1f%%",hire_rate),
             retention_12mo=sprintf("%.1f%%",retention_12mo),
             avg_ttf=sprintf("%.0f days",avg_ttf)) %>%
      datatable(rownames=FALSE, options=list(pageLength=10))
  })

  # ── TTF ───────────────────────────────────────────────────
  output$chart_ttf_hist <- renderPlotly({
    plot_ly(fats(), x=~time_to_fill, type="histogram", nbinsx=30,
            marker=list(color="#1976D2",line=list(color="white",width=0.5))) %>%
      layout(shapes=list(list(type="line",x0=60,x1=60,y0=0,y1=1,yref="paper",
                              line=list(color="red",dash="dash",width=2))),
             xaxis=list(title="Days to Fill"), yaxis=list(title="Count"),
             annotations=list(list(x=62,y=0.95,xref="x",yref="paper",
                                   text="60-day target",showarrow=FALSE,
                                   font=list(color="red",size=11))))
  })
  output$chart_ttf_over <- renderPlotly({
    x <- d$ttf_dept %>% filter(avg_ttf > 60) %>% arrange(desc(avg_ttf))
    plot_ly(x, x=~department, y=~avg_ttf, type="bar",
            marker=list(color="#E53935"),
            text=~sprintf("%.0fd",avg_ttf), textposition="outside") %>%
      layout(shapes=list(list(type="line",x0=0,x1=1,xref="paper",y0=60,y1=60,
                              line=list(color="navy",dash="dash",width=1.5))),
             xaxis=list(title="",tickangle=20), yaxis=list(title="Avg Days"))
  })
  output$tbl_ttf <- renderDT({
    d$ttf_dept %>%
      mutate(avg_ttf=sprintf("%.0f days",avg_ttf),
             median_ttf=sprintf("%.0f days",median_ttf),
             vacancy_rate=sprintf("%.1f%%",vacancy_rate),
             avg_salary=scales::dollar(avg_salary)) %>%
      datatable(rownames=FALSE, options=list(pageLength=10))
  })

  # ── EEO ───────────────────────────────────────────────────
  output$chart_eeo_race <- renderPlotly({
    x <- d$eeo_race %>% filter(eeo_race != "Not Disclosed") %>%
      arrange(adverse_impact_ratio)
    plot_ly(x, x=~adverse_impact_ratio,
            y=~reorder(eeo_race, adverse_impact_ratio),
            type="bar", orientation="h",
            marker=list(color=~ifelse(flag_adverse_impact,"#E53935","#2e7d32")),
            text=~round(adverse_impact_ratio,3), textposition="outside") %>%
      layout(shapes=list(list(type="line",x0=0.80,x1=0.80,y0=0,y1=1,yref="paper",
                              line=list(color="red",dash="dash",width=2))),
             xaxis=list(title="Adverse Impact Ratio"), yaxis=list(title=""),
             margin=list(l=200,r=60))
  })
  output$chart_eeo_flow <- renderPlotly({
    x <- d$eeo_race %>% arrange(desc(applicants))
    plot_ly(x, x=~eeo_race, y=~applicants, type="bar",
            marker=list(color="#1976D2"),
            text=~paste0(scales::comma(applicants),"\n(",pct_of_apps,"%)"),
            textposition="outside") %>%
      layout(xaxis=list(title="",tickangle=25),yaxis=list(title="Applicants"),
             margin=list(b=80))
  })
  output$chart_eeo_gender <- renderPlotly({
    plot_ly(d$eeo_gen, labels=~eeo_gender, values=~applicants, type="pie",
            hole=0.45, textinfo="label+percent") %>%
      layout(showlegend=TRUE, margin=list(t=20,b=20))
  })
  output$tbl_eeo <- renderDT({
    d$eeo_race %>%
      mutate(hire_rate=sprintf("%.2f%%",hire_rate),
             pct_of_apps=sprintf("%.1f%%",pct_of_apps),
             pct_of_hires=sprintf("%.1f%%",pct_of_hires),
             p_value=ifelse(is.na(p_value), "reference", sprintf("%.3f", p_value)),
             p_holm=ifelse(is.na(p_holm), "reference", sprintf("%.3f", p_holm)),
             flag_adverse_impact=ifelse(flag_adverse_impact,"⚠️ Flag","✅ OK")) %>%
      rename(`Adverse Impact`=flag_adverse_impact) %>%
      datatable(rownames=FALSE)
  })

  # ── Recs ──────────────────────────────────────────────────
  output$tbl_recs <- renderDT({
    d$recs %>%
      datatable(rownames=FALSE, escape=FALSE,
                options=list(pageLength=10, dom="t",
                             columnDefs=list(list(width="45%",targets=c(0,1)))))
  })

  # ── ATS data ──────────────────────────────────────────────
  output$tbl_ats <- renderDT({
    fats() %>%
      select(req_id, department, title, source, level,
             time_to_fill, time_to_hire, applicants,
             offer_accept_rate, hired, retained_12mo, vacancy_status) %>%
      mutate(offer_accept_rate=sprintf("%.1f%%",offer_accept_rate),
             hired=ifelse(hired==1,"✅","—"),
             retained_12mo=ifelse(retained_12mo==1,"✅","—")) %>%
      datatable(rownames=FALSE, filter="top",
                options=list(pageLength=20,scrollX=TRUE))
  })
}

shinyApp(ui, server)
