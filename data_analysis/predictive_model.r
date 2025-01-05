library(caret)
library(xgboost)
library(tidyverse)

# Train predictive model
train_model <- function(data, target_var, model_type = c("regression", "classification"), 
                       method = c("xgboost", "rf", "glm")) {
  model_type <- match.arg(model_type)
  method <- match.arg(method)
  
  # Split features and target
  features <- data %>% select(-all_of(target_var))
  target <- data[[target_var]]
  
  # Set training control
  ctrl <- trainControl(
    method = "cv",
    number = 5,
    verboseIter = FALSE,
    classProbs = (model_type == "classification")
  )
  
  # Model-specific parameters
  params <- switch(method,
    "xgboost" = list(
      objective = if(model_type == "regression") "reg:squarederror" else "binary:logistic",
      eval_metric = if(model_type == "regression") "rmse" else "logloss",
      eta = 0.1,
      max_depth = 6,
      nrounds = 100
    ),
    "rf" = list(ntree = 500),
    "glm" = list()
  )
  
  # Train model
  model <- train(
    x = as.matrix(features),
    y = target,
    method = method,
    trControl = ctrl,
    tuneLength = 5,
    params = params
  )
  
  return(model)
}

# Make predictions
predict_outcomes <- function(model, new_data, type = c("raw", "prob")) {
  type <- match.arg(type)
  predictions <- predict(model, newdata = as.matrix(new_data), type = type)
  return(predictions)
}

# Evaluate model performance
evaluate_model <- function(actual, predicted, model_type = c("regression", "classification")) {
  model_type <- match.arg(model_type)
  
  if (model_type == "regression") {
    metrics <- list(
      RMSE = sqrt(mean((actual - predicted)^2)),
      MAE = mean(abs(actual - predicted)),
      R2 = cor(actual, predicted)^2
    )
  } else {
    metrics <- list(
      Accuracy = mean(actual == predicted),
      Precision = sum(actual & predicted) / sum(predicted),
      Recall = sum(actual & predicted) / sum(actual)
    )
  }
  return(metrics)
}