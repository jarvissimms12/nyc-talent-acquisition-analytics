# install.R — run once to install all dependencies
install.packages(c(
  "tidyverse",      # data manipulation + ggplot2
  "scales",         # dollar/percent formatting
  "gridExtra",      # multi-panel charts
  "lubridate",      # date handling
  "shiny",          # dashboard framework
  "shinydashboard",
  "plotly",         # interactive charts
  "DT"              # interactive tables
))
