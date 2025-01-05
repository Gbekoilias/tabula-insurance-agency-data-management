library(tidyverse)
library(scales)

# Generate comprehensive summary statistics
generate_summary <- function(data) {
  numeric_cols <- data %>% select_if(is.numeric) %>% names()
  categorical_cols <- data %>% select_if(is.character) %>% names()
  
  # Numeric summaries
  numeric_summary <- data %>%
    summarise(across(all_of(numeric_cols), 
                    list(mean = ~mean(., na.rm = TRUE),
                         median = ~median(., na.rm = TRUE),
                         sd = ~sd(., na.rm = TRUE),
                         min = ~min(., na.rm = TRUE),
                         max = ~max(., na.rm = TRUE))))
  
  # Categorical summaries
  categorical_summary <- lapply(categorical_cols, function(col) {
    data %>% count(!!sym(col), sort = TRUE)
  })
  names(categorical_summary) <- categorical_cols
  
  list(numeric = numeric_summary,
       categorical = categorical_summary)
}

# Create standard visualizations
create_plots <- function(data) {
  numeric_cols <- data %>% select_if(is.numeric) %>% names()
  categorical_cols <- data %>% select_if(is.character) %>% names()
  
  plots <- list()
  
  # Histograms for numeric variables
  plots$histograms <- map(numeric_cols, ~{
    ggplot(data, aes(x = !!sym(.x))) +
      geom_histogram(fill = "steelblue", bins = 30) +
      labs(title = paste("Distribution of", .x),
           x = .x, y = "Count") +
      theme_minimal()
  })
  
  # Bar plots for categorical variables
  plots$barplots <- map(categorical_cols, ~{
    data %>%
      count(!!sym(.x)) %>%
      ggplot(aes(x = reorder(!!sym(.x), n), y = n)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      coord_flip() +
      labs(title = paste("Frequency of", .x),
           x = .x, y = "Count") +
      theme_minimal()
  })
  
  # Correlation plot for numeric variables
  if (length(numeric_cols) > 1) {
    plots$correlation <- data %>%
      select(all_of(numeric_cols)) %>%
      cor(use = "pairwise.complete.obs") %>%
      as.data.frame() %>%
      rownames_to_column("var1") %>%
      pivot_longer(-var1, names_to = "var2", values_to = "correlation") %>%
      ggplot(aes(x = var1, y = var2, fill = correlation)) +
      geom_tile() +
      scale_fill_gradient2(low = "red", mid = "white", high = "blue", 
                          midpoint = 0, limits = c(-1, 1)) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  
  plots
}