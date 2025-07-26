library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)


blog_data <- blog_data %>%
  filter(!is.na(date_clean))

# Ensure date column is in Date format
blog_data$date <- as.Date(blog_data$date_clean)

# Count posts per author per month
monthly_data <- blog_data %>%
  mutate(month = floor_date(date, "month")) %>%
  count(author, month)

# Fill in missing months for each author with 0 posts
full_months <- seq(min(monthly_data$month), max(monthly_data$month), by = "month")

monthly_filled <- monthly_data %>%
  complete(author, month = full_months, fill = list(n = 0)) %>%
  arrange(author, month)

# Plot: true stacked area plot per month
ggplot(monthly_filled, aes(x = month, y = n, fill = author)) +
  geom_area(position = "stack", color = NA, alpha = 0.95) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  labs(
    title = "Stacked Area Plot of Blog Posts per Month by Author",
    x = "Month",
    y = "Number of Posts",
    fill = "Author"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right")



# Per year

library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)

# Count posts per author per year
yearly_data <- blog_data %>%
  mutate(year = year(date_clean)) %>%
  count(author, year)

# Fill in missing years per author with 0 posts
all_years <- seq(min(yearly_data$year), max(yearly_data$year))

yearly_filled <- yearly_data %>%
  complete(author, year = all_years, fill = list(n = 0)) %>%
  arrange(author, year)

color_palette_50 <- c(
  "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b",
  "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", "#aec7e8", "#ffbb78",
  "#98df8a", "#ff9896", "#c5b0d5", "#c49c94", "#f7b6d2", "#c7c7c7",
  "#dbdb8d", "#9edae5", "#393b79", "#637939", "#8c6d31", "#843c39",
  "#7b4173", "#5254a3", "#6b6ecf", "#9c9ede", "#8ca252", "#b5cf6b",
  "#cedb9c", "#bd9e39", "#e7ba52", "#e7969c", "#d6616b", "#e377c2",
  "#7f7f7f", "#bcbd22", "#17becf", "#1b9e77", "#d95f02", "#7570b3",
  "#e7298a", "#66a61e", "#e6ab02", "#a6761d", "#666666", "#9467bd",
  "#8dd3c7", "#fb8072"
)

# Plot
ggplot(yearly_filled, aes(x = year, y = n, fill = author)) +
  geom_area(position = "stack", color = NA, alpha = 0.95) +
  scale_fill_manual(values = color_palette_50) +
  scale_x_continuous(breaks = all_years) +
  labs(
    title = "Blog Posts per Year by Author",
    x = "Year",
    y = "Number of Posts",
    fill = "Author"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")  # Optional

# Start and end time

# Extract first and last blog post dates per author
author_span_dates <- blog_posts %>%
  filter(!is.na(date_clean)) %>%
  group_by(author) %>%
  summarise(
    first_date = min(date_clean),
    last_date = max(date_clean),
    .groups = "drop"
  )

# Create a named color vector for authors
authors <- unique(author_span_dates$author)
author_colors <- setNames(color_palette_50[seq_along(authors)], authors)

# Plot: line for span, point if only one post
ggplot(author_span_dates, aes(y = reorder(author, first_date))) +
  geom_segment(
    data = subset(author_span_dates, first_date != last_date),
    aes(x = first_date, xend = last_date, yend = author, color = author),
    linewidth = 1.5
  ) +
  scale_color_manual(values = author_colors) +
  labs(
    title = "Time of first and last blog post",
    x = "Date",
    y = "Author",
    color = "Author"
  ) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")



# Count number of unique authors per year
most_active_year <- blog_posts %>%
  filter(!is.na(date_clean)) %>%
  mutate(year = lubridate::year(date_clean)) %>%
  group_by(year) %>%
  summarise(unique_authors = n_distinct(author), .groups = "drop") %>%
  arrange(desc(unique_authors))

# View the top year
most_active_year



library(dplyr)
library(lubridate)
library(tm)
library(wordcloud)
library(RColorBrewer)

# Ensure date_clean is in Date format
blog_data <- blog_data %>%
  filter(!is.na(date_clean), !is.na(content)) %>%
  mutate(year = year(date_clean))

# Define custom stopwords
custom_stopwords <- c(stopwords("en"), "also", "one", "two", "use", "used", "using", "can", "will", "get", "like", "just", "make", "many", "'s", "-", "'re")

# Loop through each year and create a word cloud
unique_years <- sort(unique(blog_data$year))

for (yr in unique_years) {
  cat("Generating word cloud for", yr, "...\n")
  
  text_data <- blog_data %>%
    filter(year == yr) %>%
    pull(content) %>%
    paste(collapse = " ")
  
  # Create a text corpus
  corpus <- Corpus(VectorSource(text_data))
  corpus <- corpus %>%
    tm_map(content_transformer(tolower)) %>%
    tm_map(removePunctuation) %>%
    tm_map(removeNumbers) %>%
    tm_map(removeWords, custom_stopwords) %>%
    tm_map(stripWhitespace)
  
  # Create term-document matrix
  tdm <- TermDocumentMatrix(corpus)
  m <- as.matrix(tdm)
  word_freqs <- sort(rowSums(m), decreasing = TRUE)
  wordcloud_data <- data.frame(word = names(word_freqs), freq = word_freqs)
  
  # Plot word cloud
  wordcloud(
    words = wordcloud_data$word,
    freq = wordcloud_data$freq,
    min.freq = 2,
    max.words = 100,
    random.order = FALSE,
    colors = brewer.pal(8, "Dark2")
  )
  title(paste("Most Common Words in", yr))
}



library(quanteda)
library(stopwords)
library(wordcloud)
library(RColorBrewer)
library(dplyr)
library(lubridate)

# Prepare data
blog_data <- blog_data %>%
  filter(!is.na(date_clean), !is.na(content)) %>%
  mutate(year = year(date_clean))

# Loop through each year
for (yr in sort(unique(blog_data$year))) {
  cat("Generating word cloud for", yr, "...\n")
  
  # Combine all blog content for the year
  text_data <- blog_data %>%
    filter(year == yr) %>%
    pull(content) %>%
    paste(collapse = " ")
  
  # Create corpus and tokens
  corpus <- corpus(text_data)
  toks <- tokens(corpus, remove_punct = TRUE, remove_numbers = TRUE) %>%
    tokens_tolower() %>%
    tokens_remove(stopwords("en", source = "snowball")) %>%
    tokens_remove(c("also", "one", "two", "use", "used", "using", "can", "will", "get", "like", "just", "make", "many"))  # custom stopwords
  
  # Create document-feature matrix
  dfm_year <- dfm(toks)
  top_words <- topfeatures(dfm_year, n = 100)
  
  # Generate word cloud
  wordcloud(
    words = names(top_words),
    freq = top_words,
    min.freq = 2,
    max.words = 100,
    random.order = FALSE,
    colors = brewer.pal(8, "Dark2")
  )
  title(paste("Most Common Words in", yr))
}

