library(xml2)
library(rvest)
library(dplyr)
library(stringr)
library(fs)
library(tidyr)
library(httr)

# Set the image output directory
img_dir <- "C:/Users/DLakens/OneDrive - TU Eindhoven/R/open_science_blogs/app/www/local_images"
dir.create(img_dir, recursive = TRUE, showWarnings = FALSE)

# Function to safely download images
safe_download_image <- function(url, local_path) {
  if (file.exists(local_path)) return(TRUE)
  tryCatch({
    ua <- user_agent("Mozilla/5.0")
    res <- GET(url, ua, write_disk(local_path, overwrite = TRUE), timeout(15))
    if (status_code(res) >= 400 || file.info(local_path)$size < 10) stop("Download failed or file too small")
    TRUE
  }, error = function(e) {
    message(sprintf("❌ Failed to download %s: %s", url, e$message))
    write(url, file = file.path(img_dir, "missing_images.txt"), append = TRUE)
    FALSE
  })
}

# Function to extract full image URLs from HTML
extract_image_urls <- function(html) {
  doc <- read_html(html)
  imgs <- html_nodes(doc, "img")
  srcs <- html_attr(imgs, "src")
  srcs[!is.na(srcs)]
}

# Extract image URLs and associate with blog post ID
image_filenames <- blog_posts %>%
  mutate(image_urls = lapply(content_html, extract_image_urls)) %>%
  select(id, image_urls) %>%
  unnest(image_urls)

blog_posts <- blog_posts %>%
  mutate(
    blog_source_folder = str_match(file, "blogs_clean/([^/]+)/")[,2]
  )


# Create local filenames and paths
image_filenames <- image_filenames %>%
  mutate(
    # Strip ? and # fragments before creating filenames
    original_url = image_urls,
    clean_base = strsplit(basename(image_urls), "[?#]") |> sapply(`[`, 1),
    new_filename = paste0(id, "_", clean_base),
    new_filename = substr(new_filename, 1, 40),
    new_filename = gsub("[^a-zA-Z0-9._-]", "_", new_filename),
    local_path = file.path(img_dir, new_filename)
  )

image_filenames <- image_filenames %>%
  left_join(blog_posts %>% select(id, blog_source_folder), by = "id")


# Index archive
archive_root <- "C:/open_science_blogs"
all_archive_files <- dir(archive_root, 
                         pattern = "\\.(jpg|jpeg|png|gif|bmp|webp)$", 
                         recursive = TRUE, 
                         full.names = TRUE, 
                         ignore.case = TRUE)
archive_index <- setNames(all_archive_files, basename(all_archive_files))
# Additional archive folders to check
# Extra archive directories to fall back to
extra_archives <- c(
  "C:/Users/DLakens/OneDrive - TU Eindhoven/R/open_science_blogs/images",
  "C:/Users/DLakens/OneDrive - TU Eindhoven/R/open_science_blogs/app/www/downloaded_and_archived"
)

# Download or copy images
for (i in seq_len(nrow(image_filenames))) {
  img_url <- image_filenames$original_url[i]
  # Skip base64 or data URLs
  if (grepl("^data:", img_url)) {
    message(sprintf("⏭️ Skipping embedded base64 image (not supported): %s", substr(img_url, 1, 60)))
    next
  }
  
  local_path <- image_filenames$local_path[i]
  new_filename <- image_filenames$new_filename[i]
  blog_folder <- image_filenames$blog_source_folder[i]
  
  if (file.exists(local_path)) {
    message(sprintf("⏩ Skipping %s (already exists)", new_filename))
    next
  }
  
  clean_name <- strsplit(basename(img_url), "[?#]")[[1]][1]
  downloaded <- FALSE
  copied <- FALSE
  
  # 1. Attempt download if URL
  if (grepl("^https?://", img_url)) {
    downloaded <- safe_download_image(img_url, local_path)
  }
  
  # 2. Attempt local copy if download failed
  if (!downloaded && !file.exists(local_path)) {
    candidate_paths <- character()
    
    # a. Check specific blog folder
    if (!is.na(blog_folder)) {
      preferred_path <- file.path("C:/open_science_blogs", blog_folder)
      preferred_candidates <- dir(preferred_path, pattern = fixed(clean_name), 
                                  recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
      candidate_paths <- c(candidate_paths, preferred_candidates)
    }
    
    # b. Archive index match
    archive_match <- archive_index[clean_name]
    if (!is.na(archive_match) && file.exists(archive_match)) {
      candidate_paths <- c(candidate_paths, archive_match)
    }
    
    # c. Fallback directories
    for (extra_dir in extra_archives) {
      clean_name <- substr(strsplit(basename(img_url), "[?#]")[[1]][1], 1, 40)
      safe_pattern <- glob2rx(paste0("*", clean_name))
      fallback_matches <- dir(extra_dir, pattern = safe_pattern, 
                              recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
      if (length(fallback_matches) > 0) {
        candidate_paths <- c(candidate_paths, fallback_matches)
      }
    }
    
    # d. Copy first valid file
    for (src in unique(candidate_paths)) {
      if (file.exists(src)) {
        file_copy(src, local_path, overwrite = FALSE)
        copied <- TRUE
        break
      }
    }
  }
  
  # 3. Final result message
  if (file.exists(local_path)) {
    source_type <- if (downloaded) "downloaded" else "copied"
    message(sprintf("✅ Image %s (%s)", new_filename, source_type))
  } else {
    message(sprintf("❌ Could not obtain image: %s", img_url))
    write(img_url, file = file.path(img_dir, "missing_images.txt"), append = TRUE)
  }
}


# Create lookup for rewriting HTML
filename_lookup <- image_filenames %>%
  distinct(id, original_url, new_filename)

# Rewriting function for HTML
process_html <- function(html_text, post_id) {
  if (!is.character(html_text) || is.na(html_text)) return(NA_character_)
  doc <- read_html(html_text)
  imgs <- html_nodes(doc, "img")
  
  for (img in imgs) {
    src <- html_attr(img, "src")
    if (!is.na(src)) {
      new_name <- filename_lookup %>%
        filter(id == post_id, original_url == src) %>%
        pull(new_filename)
      
      if (length(new_name) == 1 && !is.na(new_name)) {
        new_path <- file.path("images", new_name)
        xml_set_attr(img, "src", new_path)
        
        parent <- xml_parent(img)
        if (xml_name(parent) == "a" && grepl("\\.(jpg|jpeg|png|gif|bmp|webp)$", html_attr(parent, "href"), ignore.case = TRUE)) {
          xml_set_attr(parent, "href", new_path)
        }
      }
    }
  }
  
  as.character(doc)
}

# Apply to all blog posts
blog_posts$content_html_local <- mapply(
  process_html,
  blog_posts$content_html,
  blog_posts$id,
  SIMPLIFY = FALSE
) |> unlist()

# Remove the columns
blog_posts$content <- NULL
blog_posts$content_html <- NULL
blog_posts$blog_source_folder <- NULL

saveRDS(blog_posts, "blog_data_local.rds")

