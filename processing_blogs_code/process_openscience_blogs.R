library(purrr)
library(lubridate)
library(tidyverse)
library(rvest)
library(xml2)
library(dplyr)
library(readr)
library(fs)
library(stringr)

# Load the extractblog_function.R code first.

# To do

# Blog id: # 3164 content is password protected. Delete
# Blog id: # 928 is a link


# All pictures should appear, if possible. 
# Extract tags

# Some weird code in blogs: 
# (function(i,s,o,g,r,a,m){i[‘GoogleAnalyticsObject’]=r;i[r]=i[r]||function(){ (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o), m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m) })(window,document,’script’,’//www.google-analytics.com/analytics.js’,’ga’); ga(‘create’, ‘UA-63654510-1’, ‘auto’); ga(‘send’, ‘pageview’);
# Some blogs should be deleted: not a day over six 🗓️ October 14, 2009


# Unzip the archive
unzip_path <- "C:\\blogs_clean"
#unzip_path <- "C:\\open_science_blogs_test\\nicolejanz"

# Get list of all HTML files in the unzipped directory
html_files <- list.files(unzip_path, pattern = "\\.html?$", recursive = TRUE, full.names = TRUE)

# Extract data from all HTML files
blog_posts <- map_dfr(html_files, extract_blog_info)

# First, clean the dates
blog_posts <- blog_posts %>%
  mutate(
    date_clean = str_trim(date),
    date_clean = str_replace_all(date_clean, "[\\r\\n\\u00A0]", ""),
    date_clean = str_squish(date_clean),
    date_clean = str_remove(date_clean, "^\\w+,\\s*"),
    date_clean = case_when(
      str_detect(date_clean, "^\\d{4}-\\d{2}-\\d{2}$") ~ date_clean,
      str_detect(date_clean, "^\\d{1,2} \\w+ \\d{4}$") ~ as.character(dmy(date_clean)),
      str_detect(date_clean, "^\\w+ \\d{1,2}, \\d{4}$") ~ as.character(mdy(date_clean)),
      str_detect(date_clean, "^\\w+ \\d{4}$") ~ as.character(my(date_clean)),
      str_detect(date_clean, "^\\d{4}$") ~ paste0(date_clean, "-01-01"),
      TRUE ~ NA_character_
    ),
    date_clean = as.Date(date_clean)
  )

blog_posts$content_html <- sub("Share this:.*", "", blog_posts$content_html)
blog_posts$content <- sub("Share this:.*", "", blog_posts$content)

# Clean up some default test in blogs
blog_posts$content_html <- sub("<p>PLOS is a non-profit organization on a mission to drive open science forward with measurable, meaningful change in research publishing, policy, and practice.</p>\n\n<p>Building on a strong legacy of pioneering innovation, PLOS continues to be a catalyst, reimagining models to meet open science principles, removing barriers and promoting inclusion in knowledge creation and sharing, and publishing research outputs that enable everyone to learn from, reuse and build upon scientific knowledge.</p>\n\n<p>We believe in a better future where science is open to all, for all.</p>", "", blog_posts$content_html)
blog_posts$content <- sub("PLOS is a non-profit organization on a mission to drive open science forward with measurable, meaningful change in research publishing, policy, and practice.\n\nBuilding on a strong legacy of pioneering innovation, PLOS continues to be a catalyst, reimagining models to meet open science principles, removing barriers and promoting inclusion in knowledge creation and sharing, and publishing research outputs that enable everyone to learn from, reuse and build upon scientific knowledge.\n\nWe believe in a better future where science is open to all, for all.\n", "", blog_posts$content)
# Identify the rows where the file name contains "jamesheathers"
is_jamesheathers <- grepl("jamesheathers", blog_posts$file, ignore.case = TRUE)
# Apply replacements only on those rows
blog_posts$content[is_jamesheathers] <- sub(".*\\n\\nShare", "", blog_posts$content[is_jamesheathers])
blog_posts$content_html[is_jamesheathers] <- sub(".*Share</p>", "", blog_posts$content_html[is_jamesheathers])

# Regex pattern: (?s) turns on "dotall" so that . matches newlines
pattern <- "(?s)I write about science.*"
# Remove everything from the phrase onwards
blog_posts$content[is_jamesheathers] <- sub(pattern, "", blog_posts$content[is_jamesheathers], perl = TRUE)
blog_posts$content_html[is_jamesheathers] <- sub(pattern, "", blog_posts$content_html[is_jamesheathers], perl = TRUE)

is_leejussim <- grepl("leejussim", blog_posts$file, ignore.case = TRUE)
pattern <- "(?s)Get the help.*"
# Remove everything from the phrase onwards
blog_posts$content[is_leejussim] <- sub(pattern, "", blog_posts$content[is_leejussim], perl = TRUE)
blog_posts$content_html[is_leejussim] <- sub(pattern, "", blog_posts$content_html[is_leejussim], perl = TRUE)
pattern <- "(?s)Lee Jussim, Ph.D., is a social psychologist.*"
# Remove everything from the phrase onwards
blog_posts$content[is_leejussim] <- sub(pattern, "", blog_posts$content[is_leejussim], perl = TRUE)
blog_posts$content_html[is_leejussim] <- sub(pattern, "", blog_posts$content_html[is_leejussim], perl = TRUE)


 blog_posts <- blog_posts %>%
  mutate(
    title = str_remove_all(title, "^(Open Science Collaboration Blog · |Daniel Simons: |Get Syeducated: |Patrick S. Forscher: |Nick Brown's blog: |Xenia Schmalz's blog: |Invariances: |BayesFactor: Software for Bayesian inference: |Crystal Prison Zone: |The 20% Statistician: |sometimes i'm wrong: |BishopBlog: )"),
    title = str_trim(title),
    title = str_remove_all(title, " :: Ian Hussey| - NeuroAnaTody| \\| Statistical Modeling, Causal Inference, and Social Science| - PSI-CHOLOGY.com - Dr. Dorian J. Primestein| - PSI-CHOLOGY.com|  - Absolutely Maybe.html| - Absolutely Maybe| _ by James Heathers _ Medium.html| – Association for Psychological Science – APS.html| \\| Political Science Replication"),
    title = str_replace_all(title, " \\| .*| – .*| — .*", "")  # Remove suffixes
  )

# Sort based on date

blog_posts <- blog_posts %>%
  arrange(date_clean)

# add ID to more easily refer to individual posts 
blog_posts$id <- 1:nrow(blog_posts)

# add author of blog
blog_posts$author[grepl("100ci", blog_posts$file)] <- "100% CI"
blog_posts$author[grepl("alexanderetz", blog_posts$file)] <- "Alexander Etz"
blog_posts$author[grepl("alexholcombe", blog_posts$file)] <- "Alex Holcombe"
blog_posts$author[grepl("allisonledgerwood", blog_posts$file)] <- "Alison Ledgerwood"
blog_posts$author[grepl("anatodorovic", blog_posts$file)] <- "Ana Todorovic"
blog_posts$author[grepl("aseinnesker", blog_posts$file)] <- "Åse Innes-Ker"
blog_posts$author[grepl("bobbiespellman", blog_posts$file)] <- "Bobbie Spellman"
blog_posts$author[grepl("brentdonnellan", blog_posts$file)] <- "Brent Donnellan"
blog_posts$author[grepl("brentroberts", blog_posts$file)] <- "Brent Roberts"
blog_posts$author[grepl("chrischambers", blog_posts$file)] <- "Chris Chambers"
blog_posts$author[grepl("cogtales", blog_posts$file)] <- "Cogtales"
blog_posts$author[grepl("daniellakens", blog_posts$file)] <- "Daniel Lakens"
blog_posts$author[grepl("dansimons", blog_posts$file)] <- "Dan Simons"
blog_posts$author[grepl("datacolada", blog_posts$file)] <- "Data Colada"
blog_posts$author[grepl("davidfunder", blog_posts$file)] <- "David Funder"
blog_posts$author[grepl("dorothybishop", blog_posts$file)] <- "Dorothy Bishop"
blog_posts$author[grepl("drprimestein", blog_posts$file)] <- "Dr. Primestein"
blog_posts$author[grepl("etiennelebel", blog_posts$file)] <- "Etienne Lebel"
blog_posts$author[grepl("felixschonbrodt", blog_posts$file)] <- "Felix Schönbrodt"
blog_posts$author[grepl("hannahwatkins", blog_posts$file)] <- "Hannah Watkins"
blog_posts$author[grepl("hildabastian", blog_posts$file)] <- "Hilda Bastian"
blog_posts$author[grepl("ianhussey", blog_posts$file)] <- "Ian Hussey"
blog_posts$author[grepl("jakewestfall", blog_posts$file)] <- "Jake Westfall"
blog_posts$author[grepl("jamesheathers", blog_posts$file)] <- "James Heathers"
blog_posts$author[grepl("jasonmitchell", blog_posts$file)] <- "Jason Mitchell"
blog_posts$author[grepl("jeffrouder", blog_posts$file)] <- "Jeff Rouder"
blog_posts$author[grepl("jimgrange", blog_posts$file)] <- "Jim Grange"
blog_posts$author[grepl("joehilgard", blog_posts$file)] <- "Joe Hilgard"
blog_posts$author[grepl("johnbargh", blog_posts$file)] <- "John Bargh"
blog_posts$author[grepl("johnsakaluk", blog_posts$file)] <- "John Sakaluk"
blog_posts$author[grepl("katiecorker", blog_posts$file)] <- "Katie Corker"
blog_posts$author[grepl("leejussim", blog_posts$file)] <- "Jee Jussim"
blog_posts$author[grepl("lornecampbell", blog_posts$file)] <- "Lorne Campbell"
blog_posts$author[grepl("michaelinzlicht", blog_posts$file)] <- "Michael Inzlicht"
blog_posts$author[grepl("moinsyed", blog_posts$file)] <- "Moin Syed"
blog_posts$author[grepl("neuroneurotic", blog_posts$file)] <- "Sam Schwarzkopf"
blog_posts$author[grepl("nickbrown", blog_posts$file)] <- "Nick Brown"
blog_posts$author[grepl("nicolejanz", blog_posts$file)] <- "Nicole Janz"
blog_posts$author[grepl("opensciencecollaboration", blog_posts$file)] <- "Open Science Collaboration"
blog_posts$author[grepl("patricklangford", blog_posts$file)] <- "Patrick Langford"
blog_posts$author[grepl("patrickforscher", blog_posts$file)] <- "Patrick Forscher"
blog_posts$author[grepl("psychfiledrawer", blog_posts$file)] <- "PsychFileDrawer"
blog_posts$author[grepl("richardmorey", blog_posts$file)] <- "Richard Morey"
blog_posts$author[grepl("richlucas", blog_posts$file)] <- "Rich Lucas"
blog_posts$author[grepl("rynesherman", blog_posts$file)] <- "Ryne Sherman"
blog_posts$author[grepl("rogerginersorolla", blog_posts$file)] <- "Roger Giner-Sorolla"
blog_posts$author[grepl("rolfzwaan", blog_posts$file)] <- "Rolf Zwaan"
blog_posts$author[grepl("sanjaysrivastava", blog_posts$file)] <- "Sanjay Srivastava"
blog_posts$author[grepl("siminevazire", blog_posts$file)] <- "Simine Vazire"
blog_posts$author[grepl("simoneschnall", blog_posts$file)] <- "Simone Schnall"
blog_posts$author[grepl("susanfiske", blog_posts$file)] <- "Susan Fiske"
blog_posts$author[grepl("statisticalmodeling", blog_posts$file)] <- "Statistical Modeling"
blog_posts$author[grepl("talyarkoni", blog_posts$file)] <- "Tal Yarkoni"
blog_posts$author[grepl("timvanderzee", blog_posts$file)] <- "Tim van der Zee"
blog_posts$author[grepl("ulischimmack", blog_posts$file)] <- "Uli Schimmack"
blog_posts$author[grepl("willgervais", blog_posts$file)] <- "Will Gervais"
blog_posts$author[grepl("xeniaschmalz", blog_posts$file)] <- "Xenia Schmalz"

# Remove those without dates (should not be necessary)
blog_posts <- blog_posts %>%
  filter(!is.na(date_clean))

saveRDS(blog_posts, file = "blog_data.rds")

library(rvest)
library(httr)
library(stringr)
library(dplyr)
library(xml2)
library(tidyr)

# Set image directory
img_dir <- "C:/blogs_clean/images"
if (!dir.exists(img_dir)) dir.create(img_dir, recursive = TRUE)

# Function to safely download an image (optional, if needed)
safe_download_image <- function(url, local_path) {
  if (file.exists(local_path)) return(TRUE)
  tryCatch({
    ua <- user_agent("Mozilla/5.0")
    res <- GET(url, ua, write_disk(local_path, overwrite = TRUE), timeout(15))
    if (status_code(res) >= 400 || file.info(local_path)$size < 100) stop("Download failed or file too small")
    TRUE
  }, error = function(e) {
    message(sprintf("Failed to download %s: %s", url, e$message))
    write(url, file = file.path(img_dir, "missing_images.txt"), append = TRUE)
    FALSE
  })
}

# Function to update HTML with local image paths
process_html <- function(html_text, post_id) {
  if (!is.character(html_text)) return(NA_character_)
  doc <- read_html(html_text)
  imgs <- html_nodes(doc, "img")
  
  for (img in imgs) {
    url <- html_attr(img, "src")
    if (!is.na(url)) {
      # Extract just the filename without query strings or resizing suffixes
      base <- basename(url)
      base <- strsplit(base, "[?#]")[[1]][1]  # Remove ? or # fragments
      base <- sub("(_resize_.*|_ssl_.*)$", "", base)  # Remove resizing suffixes
      
      fname <- paste0(post_id, "_", base)
      fname <- gsub("[^a-zA-Z0-9._-]", "_", fname)
      fname <- gsub("[^a-zA-Z0-9._-]", "_", fname)
      xml_set_attr(img, "src", file.path("images", fname))
      
      parent <- xml_parent(img)
      if (xml_name(parent) == "a") {
        xml_set_attr(parent, "href", file.path("images", fname))
      }
    }
  }
  
  as.character(doc)
}

# Apply HTML processing to all blog posts
blog_posts$content_html_local <- unlist(mapply(process_html, 
                                               blog_posts$content_html, 
                                               blog_posts$id, 
                                               SIMPLIFY = FALSE))

# OPTIONAL: If you want to extract image filenames from HTML
extract_image_filenames <- function(html) {
  doc <- read_html(html)
  imgs <- html_nodes(doc, "img")
  srcs <- html_attr(imgs, "src")
  srcs <- srcs[!is.na(srcs)]
  str_match(srcs, ".*/([^/?]+)")[, 2]
}

image_filenames_html <- blog_posts %>%
  mutate(image_files = lapply(content_html, extract_image_filenames)) %>%
  select(id, image_files) %>%
  unnest(image_files)

# OPTIONAL: List all local images (e.g., for validation)
local_image_dir <- "C:/Users/DLakens/OneDrive - TU Eindhoven/R/open_science_blogs/app/www/images"
image_filenames_app <- dir(local_image_dir,
                           pattern = "\\.(jpg|jpeg|png|gif|bmp|webp)$",
                           recursive = TRUE,
                           full.names = FALSE,
                           ignore.case = TRUE)

# Save final result
saveRDS(blog_posts, file = "blog_data.rds")


file.exists(file.path("C:/blogs_clean/images", "2905_image-31e75f.png_resize_604_2C115_ssl_1"))
file.exists(file.path("C:/blogs_clean/images", "2551_6a019b0070529b970b0224e034a6fd200d-800wi"))


# NOW COMPARE

"wpid-showering-and-bathing-by-gender.png" %in% image_filenames_app

# Step 1: Find images needed but not in the app folder
missing_from_app <- setdiff(image_filenames_html$image_files, image_filenames_app)

# Step 2: From those, find which are available in the archive
available_in_archive <- intersect(missing_from_app, image_filenames_archive)

cat("✅ Found", length(available_in_archive), "images to copy from archive to app folder.\n")

# Define paths
archive_root <- "C:/open_science_blogs"
shiny_img_dir <- "C:/Users/DLakens/OneDrive - TU Eindhoven/R/open_science_blogs/app/www/images"

# Ensure destination folder exists
dir_create(shiny_img_dir)

# Index all image files in the archive once
all_archive_files <- dir(archive_root, 
                         pattern = "\\.(jpg|jpeg|png|gif|bmp|webp)$", 
                         recursive = TRUE, 
                         full.names = TRUE, 
                         ignore.case = TRUE)

# Create a lookup table: names are just the base filenames
archive_index <- setNames(all_archive_files, basename(all_archive_files))

# Match only those needed
images_to_copy <- archive_index[basename(available_in_archive)]
images_to_copy <- images_to_copy[!is.na(images_to_copy)]


# Copy and rename to match Shiny app expectations, skipping existing files
# Step 1: Create mapping of desired filenames to original filenames
images_to_rename <- image_filenames_html %>%
  filter(image_files %in% available_in_archive) %>%
  mutate(target_name = paste0(id, "_", image_files)) %>%
  distinct(target_name, image_files)

# Step 2: Create named vector: names = target filenames, values = original filenames
rename_map <- setNames(images_to_rename$image_files, images_to_rename$target_name)

# Step 3: Copy and rename
for (target_name in names(rename_map)) {
  original_name <- rename_map[[target_name]]
  source_path <- archive_index[[original_name]]
  destination_path <- file.path(shiny_img_dir, target_name)
  
  if (!is.na(source_path) && !is.na(destination_path) &&
      nzchar(source_path) && nzchar(destination_path) &&
      !file_exists(destination_path)) {
    
    file_copy(source_path, destination_path, overwrite = FALSE)
  }
}




cat("✅ Copied and renamed", length(images_to_copy), "images to the Shiny app folder.\n")

# Save version for Shiny app

# Remove the columns
blog_posts$content <- NULL
blog_posts$content_html <- NULL

# Save the dataframe to an RDS file
saveRDS(blog_posts, "blog_data_local.rds")
