library(shiny)
library(shinyjs)

# Load user data
users <- readRDS("users.rds")

# Define UI
ui <- fluidPage(
  useShinyjs(),
  titlePanel("R Workshop Access"),
  sidebarLayout(
    sidebarPanel(
      h4("Login for Moderate/Advanced Access"),
      textInput("username", "Username"),
      passwordInput("password", "Password"),
      actionButton("login", "Login"),
      br(),
      h4("Basic Access"),
      actionButton("basic", "Go to Basic Site")
    ),
    mainPanel(
      h3("Welcome to the R Workshop for Medical Personnel"),
      p("Select your access level:"),
      p("Basic: Public access to foundational content."),
      p("Moderate/Advanced: Requires login for additional content.")
    )
  )
)

# Define server
server <- function(input, output, session) {
  observeEvent(input$basic, {
    # Redirect to basic site
    runjs("window.location.href = 'docs-basic/index.html';")
  })

  observeEvent(input$login, {
    user <- users[users$username == input$username, ]
    if (nrow(user) == 1 && user$password == input$password) {
      profile <- user$profile
      url <- paste0("docs-", profile, "/index.html")
      runjs(paste0("window.location.href = '", url, "';"))
    } else {
      showModal(modalDialog(
        title = "Login Failed",
        "Invalid username or password.",
        easyClose = TRUE
      ))
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)