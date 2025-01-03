# functions used in the analysis


library(tidyverse)
library(Matrix)
library(glmnet)
library(ncvreg)
library(picasso) # sparse model matrix scad and mcp
library(glinternet)
library(viridis)
library(hash)


# Preprocessing -------------------------------------------------

# Groub by months indexes
GroupByMONTHSets = function(mydf, month_indexes){
  month_grouped = mydf %>%
    filter(MONTH %in% month_indexes) %>% 
    dplyr::select(-MONTH) %>% 
    group_by_all() %>% 
    summarise(count = n())
  
  return(month_grouped)
}

GroupByYEARSets = function(mydf, year_indexes){
  year_grouped = mydf %>%
    filter(YEAR %in% year_indexes) %>% 
    dplyr::select(-YEAR) %>% 
    group_by_all() %>% 
    summarise(count = n())
  
  return(year_grouped)
}


# Function to subsample observations based on a threshold
Subsample_Below_Threshold <- function(df, threshold) {
  # Count the frequency of observations with counts equal to the threshold
  threshold_frequency <- sum(df$count == threshold)
  
  sub_values = unique(df$count[df$count < threshold])
  
  # keep all counts above the threshold
  df_above_threshold <- df[df$count >= threshold, ]
  
  # subsample
  for(val in sub_values){
    
    temp_index_pool = which(df$count == val)
    index_temp_sample = sample(temp_index_pool,
                               size = min(threshold_frequency, length(temp_index_pool)))
    # add the counts observation
    # to above threshold df
    df_above_threshold = bind_rows(df_above_threshold, df[index_temp_sample,])
    
  }
  
  return(df_above_threshold)
}

# used to make grouped LASSO data.frame
MapToInteger = function(vec){
  vec_uniq = unique(vec)
  res = rep(NA, length(vec))
  
  for(i in 1:length(vec)){
    res[i] = which(vec_uniq == vec[i]) - 1
  }
  
  return(res)
}

# sort of inverse of map to integer
MapToName = function(vec){
  vec_uniq = unique(vec)
  res = rep(NA, length(vec))
  
  for(i in 1:length(vec)){
    res[i] = which(vec_uniq == vec[i]) - 1
  }
  
  return(res)
}

# given a list where each element is a variable name
# and contains some values for that variables
# filter the dataframe keeping only rows with values in the list (for each variable)
KeepCommon = function(values_list, my.df){
  var_names = names(values_list)
  
  temp_df = my.df
  
  for(var_name in var_names){
    temp_df = temp_df %>% filter(!!sym(var_name) %in% values_list[[var_name]])
  }
  
  return(temp_df)
  
}


GenerateZeroCounts <- function(df_no_strat, nta_strat_df, Z = 5000) {
  
  # Initialize the zero counts data frame
  zero_counts_df <- as.data.frame(matrix(NA, nrow = Z * 12, ncol = ncol(df_no_strat)))
  colnames(zero_counts_df) <- colnames(df_no_strat)
  
  # Get unique values for each column
  unique_vals <- apply(df_no_strat, 2, unique)
  
  # Create a hash set to store existing combinations
  existing_combinations <- hash()
  
  # Add existing combinations to the hash set
  for (i in 1:nrow(df_no_strat)) {
    key <- paste(df_no_strat[i, ], collapse = "_")
    existing_combinations[[key]] <- TRUE
  }
  
  # Generate zero counts for each month
  for (month in 1:12) {
    for (i in 1:Z) {
      cond <- TRUE
      
      while (cond) {
        proposal <- sapply(unique_vals, function(el) sample(el, 1))
        proposal["MONTH"] <- factor(month, levels = 1:12)
        key <- paste(proposal, collapse = "_")
        
        if (!has.key(key, existing_combinations)) {
          zero_counts_df[(month - 1) * Z + i, ] <- proposal
          existing_combinations[[key]] <- TRUE
          cond <- FALSE
        }
      }
    }
  }
  
  # Join with NTA stratification info
  joined_zero_counts_df <- left_join(zero_counts_df, nta_strat_df, by = "NTA2020")
  
  # Clean up
  rm(df_no_strat)
  rm(zero_counts_df)
  gc()
  
  # Add count column
  joined_zero_counts_df$count <- 0
  
  joined_zero_counts_df <- joined_zero_counts_df %>% mutate(across(where(is.character), as.factor))
  
  return(joined_zero_counts_df)
}


 
# Function to create cross-validation sets
MakeMonthCvSets <- function(my_df, month_sets_ind, formula, threshold) {
  cv.sets <- list()
  
  for (i in 1:nrow(month_sets_ind)) {
    # Make sublists
    train_month_indexes = setdiff(1:12, month_sets_ind[i, ])
    test_month_indexes = month_sets_ind[i, ]
    
    cv.sets[[i]] <- list(train = list(df = NA, model_matrix = NA),
                         test = list(df = NA, model_matrix = NA))
    
    # Populate the sublists
    cv.sets[[i]]$train$df <- GroupByMONTHSets(mydf = my_df,
                                              month_indexes = train_month_indexes)
    
    cv.sets[[i]]$train$df = Subsample_Below_Threshold(df = cv.sets[[i]]$train$df, threshold = threshold)
    
    cv.sets[[i]]$train$model_matrix <- sparse.model.matrix(formula,
                                                           data = cv.sets[[i]]$train$df)
    
    cv.sets[[i]]$train$df <- data.frame(count = cv.sets[[i]]$train$df$count)
    
    # here it's the number of months considered
    cv.sets[[i]]$train$offset.constant <- length(setdiff(1:12, 1:ncol(month_sets_ind)))
    
    
    cv.sets[[i]]$test$df <- GroupByMONTHSets(mydf = my_df,
                                             month_indexes = test_month_indexes)
    
    cv.sets[[i]]$test$df = Subsample_Below_Threshold(df = cv.sets[[i]]$test$df, threshold = threshold)
    
    cv.sets[[i]]$test$model_matrix <- sparse.model.matrix(formula,
                                                          data = cv.sets[[i]]$test$df)
    
    cv.sets[[i]]$test$df <- data.frame(count = cv.sets[[i]]$test$df$count)
    
    # here it's the number of months considered
    cv.sets[[i]]$test$offset.constant <- ncol(month_sets_ind)
    gc()
  }
  
  return(cv.sets)
}

# Function to create cross-validation sets for grouped lasso glinternet
MakeMonthCvSetsGG <- function(my_df, month_sets_ind, threshold) {
  cv.sets <- list()
  
  for (i in 1:nrow(month_sets_ind)) {
    # Make sublists
    train_month_indexes = setdiff(1:12, month_sets_ind[i, ])
    test_month_indexes = month_sets_ind[i, ]
    
    cv.sets[[i]] <- list(train = list(df = NA),
                         test = list(df = NA))
    
    # Populate the sublists
    cv.sets[[i]]$train$df <- GroupByMONTHSets(mydf = my_df,
                                              month_indexes = train_month_indexes)
    
    cv.sets[[i]]$train$df = Subsample_Below_Threshold(df = cv.sets[[i]]$train$df, threshold = threshold)
    
    factor_columns <- (1:ncol(cv.sets[[i]]$train$df))[sapply(cv.sets[[i]]$train$df, is.factor)]
    
    temp_uniques_fact = apply(cv.sets[[i]]$train$df[,factor_columns], 2, unique)
    
    
    cv.sets[[i]]$train$df = KeepCommon(values_list = temp_uniques_fact,
                                       my.df = cv.sets[[i]]$train$df)
    
    # convert qualitative variables to valid format for glinternet (i.e integers {0,1,2,...})
    cv.sets[[i]]$train$df[,factor_columns] = apply(cv.sets[[i]]$train$df[,factor_columns],2, MapToInteger)
    
    
    count_index = which(colnames(cv.sets[[i]]$train$df) == "count")
    
    cv.sets[[i]]$train$model_matrix = as.matrix(cv.sets[[i]]$train$df[,-count_index])
    
    cv.sets[[i]]$train$numlevels = c(apply(cv.sets[[i]]$train$model_matrix[,1:6], 2,
                                           function(col) length(unique(col))), rep(1,9))
    
    cv.sets[[i]]$train$df <- data.frame(count = cv.sets[[i]]$train$df$count)
    
    
    # here it's the number of months considered
    cv.sets[[i]]$train$offset.constant <- length(setdiff(1:12, 1:ncol(month_sets_ind)))
    
    
    cv.sets[[i]]$test$df <- GroupByMONTHSets(mydf = my_df,
                                             month_indexes = test_month_indexes)
    
    cv.sets[[i]]$test$df = Subsample_Below_Threshold(df = cv.sets[[i]]$test$df, threshold = threshold)
    
    cv.sets[[i]]$test$df = KeepCommon(values_list = temp_uniques_fact,
                                       my.df = cv.sets[[i]]$test$df)
    
    cv.sets[[i]]$test$df[,factor_columns] = apply(cv.sets[[i]]$test$df[,factor_columns],2, MapToInteger)
    
    cv.sets[[i]]$test$model_matrix = as.matrix(cv.sets[[i]]$test$df[,-count_index])
    
    cv.sets[[i]]$test$df <- data.frame(count = cv.sets[[i]]$test$df$count)
    
    cv.sets[[i]]$test$numlevels = c(apply(cv.sets[[i]]$test$model_matrix[,1:6], 2,
                                           function(col) length(unique(col))), rep(1,9))
    
    
    # here it's the number of months considered
    cv.sets[[i]]$test$offset.constant <- ncol(month_sets_ind)
    gc()
  }
  
  return(cv.sets)
}


MakeMonthCvSetsZeros <- function(my_df, zeros_df, month_sets_ind, formula, threshold) {
  cv.sets <- list()
  
  for (i in 1:nrow(month_sets_ind)) {
    # Make sublists
    train_month_indexes = setdiff(1:12, month_sets_ind[i, ])
    test_month_indexes = month_sets_ind[i, ]
    
    zeros_train = zeros_df %>% filter(MONTH %in% train_month_indexes)
    zeros_train[,"MONTH"] = NULL
    zeros_test = zeros_df %>% filter(MONTH %in% test_month_indexes)
    zeros_test[,"MONTH"] = NULL
    
    
    cv.sets[[i]] <- list(train = list(df = NA, model_matrix = NA),
                         test = list(df = NA, model_matrix = NA))
    
    # Populate the sublists
    cv.sets[[i]]$train$df <- GroupByMONTHSets(mydf = my_df,
                                              month_indexes = train_month_indexes)
    
    cv.sets[[i]]$train$df = bind_rows(cv.sets[[i]]$train$df, zeros_train)
    
    cv.sets[[i]]$train$df = Subsample_Below_Threshold(df = cv.sets[[i]]$train$df, threshold = threshold)
    
    # just to make the sparse matrix
    cv.sets[[i]]$train$df$temp_response = 1:nrow(cv.sets[[i]]$train$df)
    
    cv.sets[[i]]$train$model_matrix <- sparse.model.matrix(formula,
                                                           data = cv.sets[[i]]$train$df)
    
    cv.sets[[i]]$train$df <- data.frame(count = cv.sets[[i]]$train$df$count)
    
    # here it's the number of months considered
    cv.sets[[i]]$train$offset.constant <- length(setdiff(1:12, 1:ncol(month_sets_ind)))
    
    
    cv.sets[[i]]$test$df <- GroupByMONTHSets(mydf = my_df,
                                             month_indexes = test_month_indexes)
    
    cv.sets[[i]]$test$df = bind_rows(cv.sets[[i]]$test$df, zeros_test)
    
    cv.sets[[i]]$test$df = Subsample_Below_Threshold(df = cv.sets[[i]]$test$df, threshold = threshold)
    
    # just to make the sparse matrix
    cv.sets[[i]]$test$df$temp_response = 1:nrow(cv.sets[[i]]$test$df)
    
    cv.sets[[i]]$test$model_matrix <- sparse.model.matrix(formula,
                                                          data = cv.sets[[i]]$test$df)
    
    cv.sets[[i]]$test$df <- data.frame(count = cv.sets[[i]]$test$df$count)
    
    # here it's the number of months considered
    cv.sets[[i]]$test$offset.constant <- ncol(month_sets_ind)
    gc()
  }
  
  return(cv.sets)
}

# Loss --------------------
# error functions
RMSEfun = function(true_vals, pred_vals){
  sqrt(mean( (true_vals - pred_vals)^2 ))
}

# Plotting -------------------
# general purpouse plots function
# assuming the parameter is one-dimensional

PlotOneDim = function(x, y, se,
                      x.min, x.1se,
                      xlab, ylab, main,
                      min.leg, onese.leg){
  
  plot(x, y,
       xlab = xlab,
       ylab = ylab,
       main = main,
       pch = 16,
       type = "b")
  
  points(x, y + se, type = "l", col = "red")
  points(x, y - se, type = "l", col = "red")
  
  # min
  abline(v = x.min, lty = 2, col = "blue", lwd = 2)
  
  # 1.se min
  abline(v = x.1se,
         lty = 2, col = "purple", lwd = 2)
  
  
  legend("topleft",
         legend = c(min.leg, onese.leg, "se"),
         col = c("blue", "purple", "red"),
         lwd = c(2, 2, 1),
         lty = c(2, 2, 1))
  
}

# generic two parameters error plots
# invert the rows order because filled.contour requires all axis values in ascending order
# the first param is assumed to be lambda: it's sorted and the logarithm is taken
TwoParErrPlot = function(model_list,
                         row_par_name = "lambda",
                         col_par_name = "alpha",
                         cv_err_matr_name = "cv.err.matr",
                         row_par_min_name = "lmin",
                         col_par_min_name = "amin",
                         my.main,
                         my.xlab = "log lambda",
                         my.ylab = "alpha"){
  
  n_row = length(model_list[[row_par_name]])
  
  # sort rows in z by increasing order to match that of lambda_vals (as required by filled.contours)
  filled.contour(x = log(model_list[[row_par_name]]) %>% sort(),
                 y = model_list[[col_par_name]],
                 z = model_list[[cv_err_matr_name]][(1:n_row) %>% sort(decreasing = TRUE),],
                 main = my.main,
                 xlab = my.xlab,
                 ylab = my.ylab,
                 color.palette = viridis::viridis,
                 nlevels = 200,
                 plot.axes = { 
                   axis(1)
                   axis(2)
                   points(log(model_list[[row_par_min_name]]), model_list[[col_par_min_name]],
                          col = "red", pch = 19, cex = 1.5)})
  
  legend("topleft",
         legend = c("min err"),
         col = "red",
         text.col = "red",
         lty = 1,
         bty = "n")
}


# CV Functions -------------------------------------------
# general purpuose lasso CV function
Lasso_CV <- function(cv.sets,
                     my.lambda.vals) {
  
  temp_err_matr <- matrix(NA, 
                          nrow = length(my.lambda.vals),
                          ncol = length(cv.sets))
  
  for (i in 1:length(cv.sets)) {
    temp_fit <- glmnet(x = cv.sets[[i]]$train$model_matrix,
                       y = log(cv.sets[[i]]$train$df$count) - # adjust for months, take logarithm
                         log(cv.sets[[i]]$train$offset.constant),
                       alpha = 1,
                       lambda = my.lambda.vals)
    
    pred_fit <- predict(temp_fit,
                        newx = cv.sets[[i]]$test$model_matrix)
    
    temp_err_matr[, i] <- apply(pred_fit, 2,
                                function(col) RMSEfun(true_vals = cv.sets[[i]]$test$df$count,
                                                      pred_vals = exp(col +
                                                                        log(cv.sets[[i]]$test$offset.constant))))
    
    rm(temp_fit)
    rm(pred_fit)
    gc()
  }
  
  # Compute error matrix and lambda min and 1se
  cv_err_matr <- cbind(apply(temp_err_matr, 1, mean),
                       apply(temp_err_matr, 1, sd) / sqrt(ncol(temp_err_matr))) %>% as.data.frame()
  
  colnames(cv_err_matr) <- c("cv.err", "cv.se")
  
  lmin_index <- which.min(cv_err_matr$cv.err)
  
  l1se_index <- which.max(cv_err_matr[,"cv.err"] <= (cv_err_matr[lmin_index,"cv.err"] + cv_err_matr[lmin_index,"cv.se"]))
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[lmin_index]
  list_summary[["l1se"]] <- my.lambda.vals[l1se_index]
  list_summary[["cv.err.matr"]] = cv_err_matr
  
  rm(cv_err_matr)
  rm(temp_err_matr)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# general purpuose elasticnet CV function
Elastic_Cv <- function(cv.sets,
                       my.lambda.vals, # decreasing sorted
                       my.alpha.vals) {
  
  temp.err.array <- array(NA,
                          dim = c(length(my.lambda.vals),
                                  length(my.alpha.vals),
                                  length(cv.sets)))
  
  # cycle over cv sets
  for (k in 1:length(cv.sets)) {
    
    # cycle over alpha values
    for(j in 1:length(my.alpha.vals)){
      
      temp_fit <- glmnet(x = cv.sets[[k]]$train$model_matrix,
                         y = log(cv.sets[[k]]$train$df$count) - # adjust for months and population, take logarithm
                           log(cv.sets[[k]]$train$offset.constant),
                         alpha = my.alpha.vals[j],
                         lambda = my.lambda.vals)
      
      pred_fit <- predict(temp_fit,
                          newx = cv.sets[[k]]$test$model_matrix)
      
      temp.err.array[,j,k] <- apply(pred_fit, 2,
                                    function(col) RMSEfun(true_vals = cv.sets[[k]]$test$df$count,
                                                          pred_vals = exp(col +
                                                                            log(cv.sets[[k]]$test$offset.constant))))
      
      rm(temp_fit)
      rm(pred_fit)
      gc()
      
    }
    
  }
  
  # Compute error matrix
  # rows: lambda
  # cols: alpha
  cv.err.matr <- apply(temp.err.array, c(1,2), mean)
  
  # min error lambda and alpha indexes
  min_indexes = which(cv.err.matr == min(cv.err.matr), arr.ind = TRUE)
  
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  list_summary[["alpha"]] <- my.alpha.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[min_indexes[1]]
  list_summary[["amin"]] <- my.alpha.vals[min_indexes[2]]
  list_summary[["cv.err.matr"]] = cv.err.matr
  
  rm(cv.err.matr)
  rm(temp.err.array)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# grouped lasso CV function
GLasso_CV <- function(cv.sets, my.lambda.vals,
                      my.interactionPairs = matrix(c(2,6,
                                                     3,6,
                                                     4,6,
                                                     5,6), byrow = T, ncol = 2)) {
  
  temp_err_matr <- matrix(NA, 
                          nrow = length(my.lambda.vals),
                          ncol = length(cv.sets))
  
  for (i in 1:length(cv.sets)) {
    temp_fit <- glinternet(X = cv.sets[[i]]$train$model_matrix,
                        Y = log(cv.sets[[i]]$train$df$count) - # adjust for months, take logarithm
                          log(cv.sets[[i]]$train$offset.constant),
                        numLevels = cv.sets[[i]]$train$numlevels,
                        lambda = my.lambda.vals,
                        interactionPairs = my.interactionPairs)
    
    pred_fit <- predict(temp_fit,
                        X = cv.sets[[i]]$test$model_matrix,
                        "response")
    
    temp_err_matr[, i] <- apply(pred_fit, 2,
                                function(col) RMSEfun(true_vals = cv.sets[[i]]$test$df$count,
                                                      pred_vals = exp(col +
                                                                        log(cv.sets[[i]]$test$offset.constant))))
    
    rm(temp_fit)
    rm(pred_fit)
    gc()
  }
  
  # Compute error matrix and lambda min and 1se
  cv_err_matr <- cbind(apply(temp_err_matr, 1, mean),
                       apply(temp_err_matr, 1, sd) / sqrt(ncol(temp_err_matr))) %>% as.data.frame()
  
  colnames(cv_err_matr) <- c("cv.err", "cv.se")
  
  lmin_index <- which.min(cv_err_matr$cv.err)
  
  l1se_index <- which.max(cv_err_matr[,"cv.err"] <= (cv_err_matr[lmin_index,"cv.err"] + cv_err_matr[lmin_index,"cv.se"]))
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[lmin_index]
  list_summary[["l1se"]] <- my.lambda.vals[l1se_index]
  list_summary[["cv.err.matr"]] = cv_err_matr
  
  rm(cv_err_matr)
  rm(temp_err_matr)
  gc()
  
  # add all to list
  
  return(list_summary)
}


# define custom lasso predict function to not print results
my.predict.gaussian = function (object, newdata, lambda.idx = c(1:3), 
                                ...) 
{
  pred.n = nrow(newdata)
  lambda.n = length(lambda.idx)
  intcpt = matrix(rep(object$intercept[lambda.idx], pred.n), 
                  nrow = pred.n, ncol = lambda.n, byrow = T)
  Y.pred = newdata %*% object$beta[, lambda.idx] + intcpt
  return(Y.pred)
}

# general purpuose MCP or SCAD CV function
NonConvex_Cv <- function(cv.sets,
                         my.lambda.vals, # decreasing sorted
                         my.gamma.vals,
                         my.penalty = "mcp") {
  
  temp.err.array <- array(NA,
                          dim = c(length(my.lambda.vals),
                                  length(my.gamma.vals),
                                  length(cv.sets)))
  
  # cycle over cv sets
  for (k in 1:length(cv.sets)) {
    
    # cycle over alpha values
    for(j in 1:length(my.gamma.vals)){
      
      # temp_fit <- ncvreg(X = as.matrix(cv.sets[[k]]$train$model_matrix),
      #                    y = log(cv.sets[[k]]$train$df$count) - # adjust for months and population, take logarithm
      #                      log(cv.sets[[k]]$train$df$Pop1 + 1) -
      #                      log(cv.sets[[k]]$train$offset.constant),
      #                    gamma = my.gamma.vals[j],
      #                    lambda = my.lambda.vals,
      #                    penalty = my.penalty)
      
      temp_fit = picasso(X = cv.sets[[k]]$train$model_matrix,
                         Y = log(cv.sets[[k]]$train$df$count) - # adjust for months and population, take logarithm
                           log(cv.sets[[k]]$train$offset.constant),
                         method = my.penalty,
                         gamma = my.gamma.vals[j],
                         lambda = my.lambda.vals)
      
      # pred_fit <- predict(temp_fit,
      #                     X = as.matrix(cv.sets[[k]]$test$model_matrix))
      
      pred_fit  = my.predict.gaussian(temp_fit,
                                      newdata = cv.sets[[k]]$test$model_matrix,
                                      lambda.idx = 1:length(temp_fit$lambda))
      
      temp.err.array[,j,k] <- apply(pred_fit, 2,
                                    function(col) RMSEfun(true_vals = cv.sets[[k]]$test$df$count,
                                                          pred_vals = exp(col +
                                                                            log(cv.sets[[k]]$test$offset.constant))))
      
      rm(temp_fit)
      rm(pred_fit)
      gc()
      
    }
    
  }
  
  # Compute error matrix
  # rows: lambda
  # cols: alpha
  cv.err.matr <- apply(temp.err.array, c(1,2), mean)
  
  # min error lambda and alpha indexes
  min_indexes = which(cv.err.matr == min(cv.err.matr), arr.ind = TRUE)
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  list_summary[["gamma"]] <- my.gamma.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[min_indexes[1]]
  list_summary[["gmin"]] <- my.gamma.vals[min_indexes[2]]
  list_summary[["cv.err.matr"]] = cv.err.matr
  
  rm(cv.err.matr)
  rm(temp.err.array)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# general purpuose lasso CV function
#' @param my.offset_constant_train (int): take the log and add to train fold offset (same for all folds)
#' @param my.offset_constant_test (int): take the log and add to train fold offset ((same for all folds))
#' @param my.offset_var_name (char): take the log and add to train fold offset (assumed is a variable in cv sets)
Lasso_Offset_CV <- function(cv.sets,
                            my.lambda.vals,
                            my.family = poisson()) {
  
  temp_err_matr <- matrix(NA, 
                          nrow = length(my.lambda.vals),
                          ncol = length(cv.sets))
  
  for (i in 1:length(cv.sets)) {
    temp_fit <- glmnet(x = cv.sets[[i]]$train$model_matrix,
                       y = cv.sets[[i]]$train$df$count,
                       alpha = 1,
                       lambda = my.lambda.vals,
                       family = my.family,
                       offset = rep(log(cv.sets[[i]]$train$offset.constant), nrow(cv.sets[[i]]$train$df)) )
    
    pred_fit <- predict(temp_fit,
                        newx = cv.sets[[i]]$test$model_matrix,
                        newoffset = rep(log(cv.sets[[i]]$test$offset.constant), nrow(cv.sets[[i]]$test$df)),
                        type = "response")
    
    temp_err_matr[, i] <- apply(pred_fit, 2,
                                function(col) RMSEfun(true_vals = cv.sets[[i]]$test$df$count,
                                                      pred_vals = col))
    
    rm(temp_fit)
    rm(pred_fit)
    gc()
  }
  
  # Compute error matrix and lambda min and 1se
  cv_err_matr <- cbind(apply(temp_err_matr, 1, mean),
                       apply(temp_err_matr, 1, sd) / sqrt(ncol(temp_err_matr))) %>% as.data.frame()
  
  colnames(cv_err_matr) <- c("cv.err", "cv.se")
  
  lmin_index <- which.min(cv_err_matr$cv.err)
  
  l1se_index <- which.max(cv_err_matr[,"cv.err"] <= (cv_err_matr[lmin_index,"cv.err"] + cv_err_matr[lmin_index,"cv.se"]))
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[lmin_index]
  list_summary[["l1se"]] <- my.lambda.vals[l1se_index]
  list_summary[["cv.err.matr"]] = cv_err_matr
  
  rm(cv_err_matr)
  rm(temp_err_matr)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# general purpuose elasticnet CV function
Elastic_Offset_Cv <- function(cv.sets,
                              my.lambda.vals,
                              my.alpha.vals,
                              my.family = poisson()) {
  
  temp.err.array <- array(NA,
                          dim = c(length(my.lambda.vals),
                                  length(my.alpha.vals),
                                  length(cv.sets)))
  
  # cycle over cv sets
  for (k in 1:length(cv.sets)) {
    
    # cycle over alpha values
    for(j in 1:length(my.alpha.vals)){
      
      temp_fit <- glmnet(x = cv.sets[[k]]$train$model_matrix,
                         y = cv.sets[[k]]$train$df$count,
                         alpha = my.alpha.vals[j],
                         lambda = my.lambda.vals,
                         family = my.family,
                         offset = rep(log(cv.sets[[k]]$train$offset.constant), nrow(cv.sets[[k]]$train$df)))
      
      pred_fit <- predict(temp_fit,
                          newx = cv.sets[[k]]$test$model_matrix,
                          newoffset = rep(log(cv.sets[[k]]$test$offset.constant), nrow(cv.sets[[k]]$test$df)))
      
      temp.err.array[,j,k] <- apply(pred_fit, 2,
                                    function(col) RMSEfun(true_vals = cv.sets[[k]]$test$df$count,
                                                          pred_vals = col))
      
      rm(temp_fit)
      rm(pred_fit)
      gc()
      
    }
    
  }
  
  # Compute error matrix
  # rows: lambda
  # cols: alpha
  cv.err.matr <- apply(temp.err.array, c(1,2), mean)
  
  # min error lambda and alpha indexes
  min_indexes = which(cv.err.matr == min(cv.err.matr), arr.ind = TRUE)
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  list_summary[["alpha"]] <- my.alpha.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[min_indexes[1]]
  list_summary[["amin"]] <- my.alpha.vals[min_indexes[2]]
  list_summary[["cv.err.matr"]] = cv.err.matr
  
  rm(cv.err.matr)
  rm(temp.err.array)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# general purpuose negbin CV function
LASSO_NegBin_Offset_Cv <- function(cv.sets,
                                   my.lambda.vals,
                                   my.theta.vals) {
  
  temp.err.array <- array(NA,
                          dim = c(length(my.lambda.vals),
                                  length(my.theta.vals),
                                  length(cv.sets)))
  
  # cycle over cv sets
  for (k in 1:length(cv.sets)) {
    
    # cycle over alpha values
    for(j in 1:length(my.theta.vals)){
      
      temp_fit <- glmnet(x = cv.sets[[k]]$train$model_matrix,
                         y = cv.sets[[k]]$train$df$count,
                         alpha = 1,
                         lambda = my.lambda.vals,
                         family = negative.binomial(theta = my.theta.vals[j]),
                         offset = rep(log(cv.sets[[k]]$train$offset.constant), nrow(cv.sets[[k]]$train$df)))
      
      pred_fit <- predict(temp_fit,
                          newx = cv.sets[[k]]$test$model_matrix,
                          newoffset = rep(log(cv.sets[[k]]$test$offset.constant), nrow(cv.sets[[k]]$test$df)))
      
      temp.err.array[,j,k] <- apply(pred_fit, 2,
                                    function(col) RMSEfun(true_vals = cv.sets[[k]]$test$df$count,
                                                          pred_vals = col))
      
      rm(temp_fit)
      rm(pred_fit)
      gc()
      
    }
    
  }
  
  # Compute error matrix
  # rows: lambda
  # cols: alpha
  cv.err.matr <- apply(temp.err.array, c(1,2), mean)
  
  # min error lambda and alpha indexes
  min_indexes = which(cv.err.matr == min(cv.err.matr), arr.ind = TRUE)
  
  
  list_summary <- list()
  list_summary[["lambda"]] <- my.lambda.vals
  list_summary[["theta"]] <- my.theta.vals
  
  list_summary[["lmin"]] <- my.lambda.vals[min_indexes[1]]
  list_summary[["tmin"]] <- my.theta.vals[min_indexes[2]]
  list_summary[["cv.err.matr"]] = cv.err.matr
  
  rm(cv.err.matr)
  rm(temp.err.array)
  gc()
  
  # add all to list
  
  return(list_summary)
}

# Extract summary ---------------------------------------

# Function to extract the minimum value from cv.err.matr and other elements if they exist
ExtractBestPars <- function(sublist) {
  list(
    lmin = if ("lmin" %in% names(sublist)) sublist[["lmin"]] else NA,
    l1se = if ("l1se" %in% names(sublist)) sublist[["l1se"]] else NA,
    gmin = if ("gmin" %in% names(sublist)) sublist[["gmin"]] else NA,
    tmin = if ("tmin" %in% names(sublist)) sublist[["tmin"]] else NA
  )
}


ExtractBetasMainCat = function(beta_list, vec_names, unique_list){
  indexes = beta_list[["mainEffects"]][["cat"]]
  
  temp_vec = c()
  temp_names = c()
  
  for (ind in 1:length(indexes)){
    temp_vec = c(temp_vec, as.numeric(beta_list[["mainEffectsCoef"]][["cat"]][[ind]]))
    temp_names = c(temp_names, paste0(vec_names[indexes[ind]], unique_list[[vec_names[indexes[ind]]]]))
    
  }
  
  
  temp_df = cbind(temp_names, temp_vec)
  
  return(temp_df)
  
}

ExtractBetasMainCont = function(beta_list, vec_names){
  indexes = beta_list[["mainEffects"]][["cont"]]
  
  temp_vec = c()
  temp_names = c()
  
  for (ind in 1:length(indexes)){
    temp_vec = c(temp_vec, as.numeric(beta_list[["mainEffectsCoef"]][["cont"]][[ind]]))
    temp_names = c(temp_names, vec_names[indexes[ind]])
    
  }
  
  
  temp_df = cbind(temp_names, temp_vec)
  
  return(temp_df)
  
}

# Plot --------------------------------
# plot the first_n coef with biggest abs
PlotFirstCoefs = function(coef_vec, coef_names,
                          first_n,
                          my.main){
  indexes <- order(coef_vec, decreasing = TRUE)[1:first_n]
  
  temp_df = data.frame(beta = coef_vec[indexes], names = coef_names[indexes])
  temp_df <- temp_df[order(temp_df$beta), ]
  
  dotchart(temp_df$beta, labels = temp_df$names, pch = 16,
           main = my.main)
  
  return(temp_df)
}













