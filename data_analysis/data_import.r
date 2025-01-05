# Load required libraries
library(tidyverse)
library(data.table)
library(readr)

# Function to import and clean data
import_and_clean_data <- function(file_path) {
  # Import data based on file extension
  cleaned_data <- if (endsWith(file_path, ".csv")) {
    fread(file_path)
  } else if (endsWith(file_path, ".xlsx")) {
    readxl::read_excel(file_path)
  } else {
    stop("Unsupported file format")
  }
  
  # Basic cleaning operations
  cleaned_data <- cleaned_data %>%
    # Remove duplicate rows
    distinct() %>%
    # Remove rows with all NA values
    filter(across(everything(), ~!all(is.na(.)))) %>%
    # Convert column names to snake_case
    rename_all(~str_to_lower(str_replace_all(., "\\s+", "_"))) %>%
    # Trim whitespace from character columns
    mutate(across(where(is.character), str_trim))
  
  return(cleaned_data)
}

# Error handling wrapper
safe_import <- function(file_path) {
  tryCatch(
    import_and_clean_data(file_path),
    error = function(e) {
      message("Error importing data: ", e$message)
      return(NULL)
    }
  )
}