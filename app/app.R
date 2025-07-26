library(shiny)
library(dplyr)
library(bslib)

blog_data <- readRDS("blog_data_local.rds") %>% arrange(date_clean)

japanese_theme <- bs_theme(
  version = 5,
  base_font = font_google("Noto Sans"),
  heading_font = font_google("Noto Sans"),
  primary = "#264653",     # Indigo blue
  secondary = "#a8c686",   # Matcha green
  success = "#f9ccd3",     # Sakura pink
  bg = "#fefefe",          # Rice paper white
  fg = "#2a2a2a"           # Charcoal ink
)

ui <- fluidPage(
  theme = japanese_theme,
  tags$head(
    tags$style(HTML("
    
          .highlight {
        background-color: #f9ccd3; /* Sakura pink */
        padding: 2px 4px;
        border-radius: 4px;
      }

      $(document).on('keypress', '#search_term', function(e) {
          if (e.which == 13) {
            $('#search_btn').click();
            return false;
          }
        });

      .blog-box {
        background-color: #fefefe;
        border-radius: 12px;
        padding: 25px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        animation: fadeIn 0.6s ease-in-out;
      }
      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
      }
      .btn-custom {
        margin-top: 10px;
        font-weight: bold;
        border-radius: 8px;
      }
      .blog-link {
        margin-top: 10px;
        display: block;
        font-size: 16px;
        color: #264653;
        font-weight: 500;
      }
    "))
  ),
  titlePanel("Open Science Blog Browser"),
  sidebarLayout(
    sidebarPanel(
      textInput("search_term", "🔍 Search blog content:", placeholder = "Enter a keyword..."),
      actionButton("search_btn", "Search", class = "btn btn-primary btn-custom"),
      dateInput("selected_date", "📅 Select a date:", value = min(blog_data$date_clean),
                min = min(blog_data$date_clean), max = max(blog_data$date_clean)),
      actionButton("prev_btn", "⬅️ Previous", class = "btn btn-primary btn-custom"),
      actionButton("next_btn", "Next ➡️", class = "btn btn-primary btn-custom"),
      actionButton("random_btn", "🎲 Random Blog Post", class = "btn btn-warning btn-custom"),
      actionButton("today_btn", "🎉 Happening Today", class = "btn btn-success btn-custom")
    ),
    mainPanel(
      div(class = "blog-box",
          h3(textOutput("blog_title")),
          h4(textOutput("blog_author")),
          h5(textOutput("blog_date")),
          h5(textOutput("blog_id")),
          uiOutput("blog_link"),
          tags$hr(),
          htmlOutput("blog_content")
      )
    )
  )
)

server <- function(input, output, session) {
  current_index <- reactiveVal(1)
  
  # Filtered data based on search term
  search_trigger <- reactiveVal(0)
  
  observeEvent(input$search_btn, {
    search_trigger(search_trigger() + 1)
    
    # Reset index to 1 if results exist
    if (nrow(filtered_data()) > 0) {
      current_index(1)
      updateDateInput(session, "selected_date", value = filtered_data()$date_clean[1])
    } else {
      showNotification("No blog posts found for that search term.", type = "warning")
    }
  })
  
  filtered_data <- eventReactive(search_trigger(), {
    if (input$search_term == "") {
      blog_data
    } else {
      blog_data %>% filter(grepl(input$search_term, content, ignore.case = TRUE))
    }
  })
  
  # Show a random post on app load
  observeEvent(TRUE, {
    current_index(sample(nrow(filtered_data()), 1))
    updateDateInput(session, "selected_date", value = filtered_data()$date_clean[current_index()])
  }, once = TRUE)
  
  observeEvent(input$selected_date, {
    index <- which(filtered_data()$date_clean >= input$selected_date)
    current_index(if (length(index) > 0) index[1] else nrow(filtered_data()))
  })
  
  observeEvent(input$next_btn, {
    if (current_index() < nrow(filtered_data())) {
      current_index(current_index() + 1)
      updateDateInput(session, "selected_date", value = filtered_data()$date_clean[current_index()])
    }
  })
  
  observeEvent(input$prev_btn, {
    if (current_index() > 1) {
      current_index(current_index() - 1)
      updateDateInput(session, "selected_date", value = filtered_data()$date_clean[current_index()])
    }
  })
  
  # Random Blog Post button
  observeEvent(input$random_btn, {
    current_index(sample(nrow(filtered_data()), 1))
    updateDateInput(session, "selected_date", value = filtered_data()$date_clean[current_index()])
  })
  
  observeEvent(input$today_btn, {
    today_md <- format(Sys.Date(), "%m-%d")
    temp_data <- filtered_data()
    md_values <- format(temp_data$date_clean, "%m-%d")
    diffs <- abs(as.numeric(as.Date(paste0("2000-", md_values)) - as.Date(paste0("2000-", today_md))))
    min_diff <- min(diffs)
    candidates <- which(diffs == min_diff)
    closest_index <- sample(candidates, 1)
    current_index(closest_index)
    updateDateInput(session, "selected_date", value = temp_data$date_clean[closest_index])
  })
  
  
  output$blog_title <- renderText({
    filtered_data()$title[current_index()]
  })
  
  output$blog_author <- renderText({
    filtered_data()$author[current_index()]
  })
  
  output$blog_date <- renderText({
    paste("🗓️", format(filtered_data()$date_clean[current_index()], "%B %d, %Y"))
  })
  
  output$blog_link <- renderUI({
    url <- filtered_data()$url[current_index()]
    if (!is.na(url) && url != "") {
      tags$a(href = url, "🔗 Link to original blog", target = "_blank", class = "blog-link")
    }
  })
  
  output$blog_id <- renderText({
    paste("️Blog id: #", filtered_data()$id[current_index()])
  })
  
output$blog_content <- renderUI({
  content <- filtered_data()$content_html_local[current_index()]
  
  if (input$search_term != "") {
    # Escape special characters in search term for regex
    term <- input$search_term
    term_escaped <- gsub("([\\W])", "\\\\\\1", term, perl = TRUE)
    
    # Highlight all instances of the term
    content <- gsub(
      paste0("(?i)(", term_escaped, ")"),
      "<span class='highlight'>\\1</span>",
      content,
      perl = TRUE
    )
  }
  
  HTML(content)
})

}

shinyApp(ui = ui, server = server)
