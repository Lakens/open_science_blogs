extract_blog_info <- function(file) {
  # Print the name of the file being processed
  message("Processing file: ", file)
  
  page <- read_html(file, encoding = "UTF-8")

  # This line removes the entire privacy warning block
  xml_remove(html_elements(page, "
  .cky-consent-container,
  .cky-overlay,
  .cky-consent-bar,
  .cky-notice,
  .cky-title,
  .cky-description,
  .cky-iab-preference-des,
  .cky-cookie-des-table,
  .pt-user-privacy,
  .detail-iab-description,
  .cky-iab-detail-wrapper,
  .footer,
  .site-footer,
  .magazine-cover-feature__highlight,
  .nav--tests--description,
  .blog_entry--full__review-info-text
"))
  
  
  # Continue with your content extraction
  article <- html_node(page, "div.entry-content")
  content <- if (!is.null(article)) html_text(article, trim = TRUE) else NA
  
  
  # Step 1: Try to extract from div.entry-content
  article <- html_node(page, "div.entry-content")
  content <- if (!is.null(article)) html_text(article, trim = TRUE) else NA
  content_html <- if (!is.null(article)) as.character(article) else NA
  
  # Step 2: Fallback – extract all <p> tags if content is still missing
  if (is.na(content) || content == "") {
    paragraphs <- html_nodes(page, "p")
    content <- if (length(paragraphs) > 0) {
      paste(html_text(paragraphs, trim = TRUE), collapse = "\n\n")
    } else {
      NA
    }
    
    content_html <- if (length(paragraphs) > 0) {
      paste(as.character(paragraphs), collapse = "\n\n")
    } else {
      NA
    }
  }
  
  
  # Title from <title>, <h1>, or <h2>
  title <- html_text(html_node(page, "title"))
  if (is.na(title) || title == "") {
    title_node <- html_node(page, "h1")
    if (is.null(title_node)) {
      title_node <- html_node(page, "h2")
    }
    title <- if (!is.null(title_node)) html_text(title_node, trim = TRUE) else NA
  }
  
  
  # Step 1: Try h2.date-header > span, then h4.date
  date_node <- html_node(page, "h2.date-header > span, h4.date")
  date <- if (!is.null(date_node)) html_text(date_node, trim = TRUE) else NA
  # Step 1b: Try <time class="entry-date"> and extract visible text
  if (is.na(date) || date == "") {
    time_node <- html_node(page, "time.entry-date")
    if (!is.null(time_node)) {
      time_text <- html_text(time_node, trim = TRUE)
      parsed_date <- lubridate::parse_date_time(time_text, orders = c("mdy HM p", "mdy"), quiet = TRUE)
      if (is.na(parsed_date)) {
        parsed_date <- lubridate::mdy(time_text, quiet = TRUE)
      }
      if (!is.na(parsed_date)) {
        date <- format(parsed_date, "%B %d, %Y")
      }
    }
  }
  
  # Step 2: meta tag with ISO date
  if (is.na(date) || date == "") {
    meta_date <- html_attr(html_node(page, "meta[property='article:published_time']"), "content")
    if (!is.na(meta_date)) {
      parsed_date <- lubridate::ymd_hms(meta_date, quiet = TRUE)
      if (!is.na(parsed_date)) {
        date <- format(parsed_date, "%B %d, %Y")
      }
    }
  }
  # Step 3
  if (is.na(date) || date == "") {
    meta_date <- html_attr(html_node(page, "meta[itemprop='datePublished']"), "content")
    if (!is.na(meta_date)) {
      parsed_date <- ymd_hms(meta_date, quiet = TRUE)
      if (!is.na(parsed_date)) {
        date <- format(parsed_date, "%B %d, %Y")
      }
    }
  }
  
  # Step 4: 
  if (is.na(date) || date == "") {
    date_node <- html_node(page, "time.entry-date.published")
    date <- if (!is.null(date_node)) html_text(date_node, trim = TRUE) else NA
  }
  
  # Step 5. time.published (used by this blog)
  if (is.na(date) || date == "") {
    time_node <- html_node(page, "time.published")
    if (!is.null(time_node)) {
      meta_date <- html_attr(time_node, "datetime")
      if (!is.na(meta_date)) {
        parsed_date <- lubridate::ymd_hms(meta_date, quiet = TRUE)
        if (!is.na(parsed_date)) {
          date <- format(parsed_date, "%B %d, %Y")  # or "%Y-%m-%d" for ISO format
        }
      }
    }
  }
  
  
  # Step 6: 
  # Extract the canonical link
  canonical_url <- html_attr(html_node(page, "link[rel='canonical']"), "href")
  
  # Extract date from URL
  if (is.na(date) || date == "") {
    date_match <- str_match(canonical_url, "/(\\d{4})/(\\d{2})/")[,2:3]
    if (!any(is.na(date_match))) {
      date <- format(as.Date(paste(date_match[1], date_match[2], "01", sep = "-")), "%B %Y")
    } else {
      date <- NA
    }
  }
  
  # Step 7: Extract date from visible text using regex
  if (is.na(date) || date == "") {
    text_content <- html_text(page)
    
    # Match formats like "May 2, 2017 in"
    date_match <- stringr::str_match(text_content, "\\b([A-Z][a-z]+ \\d{1,2}, \\d{4}(?: \\d{1,2}:\\d{2} [AP]M)?)\\b")[,2]
    
    if (!is.na(date_match) && !is.null(date_match)) {
      parsed_date <- lubridate::mdy(date_match, quiet = TRUE)
      if (!is.na(parsed_date)) {
        date <- format(parsed_date, "%B %d, %Y")
      }
    }
  }
  
  
  
  # Step 1: Try to extract from h2.title > a (most reliable for this blog)
  title_link <- page %>%
    html_node("h2.title a") %>%
    html_attr("href")
  
  # Step 2: Try Open Graph URL
  og_url <- page %>%
    html_node("meta[property='og:url']") %>%
    html_attr("content")
  
  # Step 3: Try WordPress shortlink
  shortlink <- page %>%
    html_node("link[rel='shortlink']") %>%
    html_attr("href")
  
  # Step 4: Try canonical link
  canonical <- page %>%
    html_node("link[rel='canonical']") %>%
    html_attr("href")
  
  # Step 5: Fallback to first internal post link (not external references)
  internal_links <- page %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset("^https?://centerforopenscience\\.github\\.io") %>%
    unique()
  
  # Step 6: Combine with fallback logic
  url <- title_link
  if (is.na(url) || url == "") url <- og_url
  if (is.na(url) || url == "") url <- shortlink
  if (is.na(url) || url == "") url <- canonical
  if ((is.na(url) || url == "") && length(internal_links) > 0) url <- internal_links[1]
  
  
  return(data.frame(
    file = file,
    title = title,
    date = date,
    content = content,
    content_html = content_html,
    url = url,
    stringsAsFactors = FALSE
  ))
}

