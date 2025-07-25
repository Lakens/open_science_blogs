# This script takes all the downloaded blogs, and does some heavy cleaning as far as it could be automated. 
# This cleaning was not sufficient, and was followed by manually deleting files. 
# The cleaning process is not completely computationally reproducible. 

# Load required libraries
library(fs)
library(stringr)

# Define source and target directories
src_dir <- "C:/open_science_blogs/replicationnetwork"
target_dir <- "C:/open_science_blogs_test"

# Create the target directory if it doesn't exist
dir_create(target_dir)

# Get all subdirectories recursively
all_folders <- dir_ls(src_dir, recurse = TRUE, type = "directory")

# Filter folders that are named like years between 2006 and 2025
year_folders <- all_folders[
  basename(all_folders) %in% as.character(2006:2025)
]

# Copy each matching folder to the target directory, preserving structure
for (folder in year_folders) {
  # Reconstruct relative path from source
  rel_path <- path_rel(folder, start = src_dir)
  dest_path <- path(target_dir, rel_path)
  
  # Create parent folders if needed
  dir_create(path_dir(dest_path))
  
  # Copy entire folder contents
  dir_copy(folder, dest_path)
}

cat("Done: Year-named folders copied.\n")


# Set root path
root <- "C:/open_science_blogs_test"

# Recursively list all files and folders
all_paths <- dir_ls(root, recurse = TRUE, type = "any")

# Delete specific folders
folders_to_delete <- all_paths[
  dir_exists(all_paths) &
    (
      str_detect(all_paths, "hts-cache$") |
        basename(all_paths) == "wordpress.com" |
        str_detect(all_paths, "public-api\\.wordpress\\.com$") |
        str_detect(all_paths, "%3frelatedposts%3d1") |
        str_detect(all_paths, "like_comment") |
        str_detect(all_paths, "comment-page") |
        str_detect(all_paths, "background-image_url") |
        str_detect(all_paths, "http_") |
        basename(all_paths) %in% c("feed", "feeds") |
        basename(all_paths) == "js"
    )
]


for (folder in folders_to_delete) {
  try(dir_delete(folder), silent = TRUE)
}

# Refresh file list after deletions
all_paths <- dir_ls(root, recurse = TRUE, type = "file")

# Delete specific files
files_to_delete <- all_paths[
  str_detect(all_paths, "hts-log\\.txt$") |
    str_detect(all_paths, "cookies\\.txt$") |
    str_detect(all_paths, "%3f") |
    str_detect(all_paths, "https.html") |
    str_detect(all_paths, "amp/index.html") |
    str_detect(all_paths, "iframe.html") |
    str_detect(all_paths, "backblue\\.gif$") |
    str_detect(all_paths, "GET.html") |
    str_detect(all_paths, "saved_resource") |
    str_detect(all_paths, "anchor") |
    str_detect(all_paths, "select.html") |
    str_detect(basename(all_paths), "^search.*\\.html$") |
    str_detect(all_paths, "fade\\.gif$")
]

file_delete(files_to_delete)

# Delete index.html if sibling folders have numeric names (e.g. 04, 05)
parent_dirs <- unique(dirname(all_paths))
for (dir in parent_dirs) {
  entries <- dir_ls(dir, type = "any")
  has_index <- any(basename(entries) == "index.html")
  has_number_folders <- any(dir_exists(entries) & str_detect(basename(entries), "^\\d+$"))
  if (has_index && has_number_folders) {
    index_file <- file.path(dir, "index.html")
    if (file_exists(index_file)) file_delete(index_file)
  }
}


all_paths <- dir_ls(root, recurse = TRUE, type = "file")

# Delete blogspot duplicate files (ending in 4 alphanumeric characters before .html)
html_files <- all_paths[str_detect(all_paths, "\\.html$")]
base_names <- str_replace(basename(html_files), "[0-9a-fA-F]{4}\\.html$", ".html")
dup_files <- html_files[base_names %in% basename(html_files)]

# Keep original, remove the duplicates
for (dup in dup_files) {
  if (str_detect(dup, "[0-9a-fA-F]{4}\\.html$")) {
    file_delete(dup)
  }
}

# THE STEP BELOW REMOVED SOME REAL BLOGS!
# # Delete index.html if named HTML files are in the same directory
# parent_dirs <- unique(dirname(all_paths))
# 
# for (dir in parent_dirs) {
#   htmls <- dir_ls(dir, regexp = "\\.html$", type = "file")
#   if ("index.html" %in% basename(htmls) && length(htmls) > 1) {
#     index_file <- file.path(dir, "index.html")
#     if (file_exists(index_file)) file_delete(index_file)
#   }
# }

cat("Cleanup completed.\n")

