library(shiny)
library(sentryR)

api_url <- "http://127.0.0.1:8080/predict"
log <- log4r::logger()


sentryR::configure_sentry(
  dsn = Sys.getenv("SENTRY_KEY"),
  app_name = "do4ds",
  app_version = "1.0.0"
)

ui <- fluidPage(
  titlePanel("Penguin Mass Predictor"),

  # Model input values
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        "bill_length",
        "Bill Length (mm)",
        min = 30,
        max = 60,
        value = 45,
        step = 0.1
      ),
      selectInput(
        "sex",
        "Sex",
        c("Male", "Female")
      ),
      selectInput(
        "species",
        "Species",
        c("Adelie", "Chinstrap", "Gentoo")
      ),
      # Get model predictions
      actionButton(
        "predict",
        "Predict"
      )
    ),

    mainPanel(
      h2("Penguin Parameters"),
      verbatimTextOutput("vals"),
      h2("Predicted Penguin Mass (g)"),
      textOutput("pred")
    )
  )
)

server <- function(input, output, session) {
  log4r::info(log, "App Started")


    get_browser_info <- function() {
    user_agent <- session$request$HTTP_USER_AGENT # browser
    remote_addr <- session$request$REMOTE_ADDR # ip
    
    list(
      user_agent = if (is.null(user_agent)) "Unknown" else user_agent,
      remote_addr = if (is.null(remote_addr)) "Unknown" else remote_addr
    )
  }

  error_handler <- function() {
    e <- get("e", envir = parent.frame())
    stack_trace <- shiny::printStackTrace(e) |>
      utils::capture.output(type = "message") |>
      list()
    browser <- get_browser_info()
    
    # Send the original error object with additional context to Sentry
    sentryR::capture(
      message = conditionMessage(e),
      extra = list(
        Browser = browser$user_agent,
        IP = browser$remote_addr,
        "Stack trace" =  stack_trace
      )
    )
  }

  options(shiny.error = error_handler)




  # Input params
  vals <- reactive({
  # Send as a list containing one record
  list(
    list(
      bill_length_mm = input$bill_length,
      species_Chinstrap = input$species == "Chinstrap",
      species_Gentoo = input$species == "Gentoo", 
      sex_male = input$sex == "Male"
    )
  )
})

  # Fetch prediction from API
  pred <- eventReactive(
    input$predict,
    {
      log4r::info(log, "Prediction Requested")
      r <- httr2::request(api_url) |>
        httr2::req_body_json(vals()) |>
        httr2::req_perform()
      log4r::info(log, "Prediction Returned")

      if (httr2::resp_is_error(r)) {
        log4r::error(log, paste("HTTP Error"))
      }

      httr2::resp_body_json(r)
    },
    ignoreInit = TRUE
  )

  # Render to UI
  output$pred <- renderText(pred()$predict[[1]])
  output$vals <- renderPrint(vals())
}

# Run the application
shinyApp(ui = ui, server = server)