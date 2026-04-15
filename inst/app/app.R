library(ADS8192)
library(shiny)

data("example_se")

app <- run_app(se = example_se, return_as_list = TRUE)

shinyApp(ui = app$ui, server = app$server)
