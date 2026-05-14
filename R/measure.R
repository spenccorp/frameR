# frameR/R/measure.R
# Frame strength measurement, bootstrap inference,
# permutation testing, and relative emphasis

#' Measure frame strength across time periods
#'
#' The core function of the frameR package. Measures the strength
#' of theoretically specified frames in topic-relevant discourse
#' across two time periods, quantifies uncertainty through bootstrap
#' inference, tests for between-period differences using permutation
#' tests, and computes relative frame emphasis scores.
#'
#' @param embeddings A numeric matrix of sentence embeddings returned
#'   by \code{\link{embed_corpus}}.
#' @param topic_mask A logical vector returned by
#'   \code{\link{identify_topic_sentences}}.
#' @param keyword_embeddings A named list returned by
#'   \code{\link{embed_keywords}}.
#' @param periods A named list of length-2 numeric vectors specifying
#'   the start and end year of each period. Exactly two periods are
#'   required for permutation testing.
#'   Example:
#'   \code{list(
#'     Latency    = c(1997, 2011),
#'     Activation = c(2012, 2022)
#'   )}
#' @param years A numeric vector of the same length as \code{sentences}
#'   giving the year of each sentence. Used to assign sentences to
#'   periods.
#' @param n_bootstrap Integer. Number of bootstrap iterations.
#'   Default 10000. Reduce to 1000 for exploratory analyses.
#' @param n_permutations Integer. Number of permutation draws for
#'   between-period significance testing. Default 10000.
#' @param seed Integer. Random seed for reproducibility. Default 42.
#'
#' @return An object of class \code{"frameR_results"} containing:
#'   \itemize{
#'     \item \code{summary}: Data frame of bootstrap summary statistics
#'       (mean, sd, 95\% CI) per frame category and period.
#'     \item \code{permutation_tests}: Data frame of between-period
#'       differences and p-values per frame category.
#'     \item \code{ratios}: Data frame of relative frame emphasis
#'       scores per frame category and period.
#'     \item \code{boot_results}: Raw bootstrap distributions.
#'       Used internally by \code{\link{plot.frameR_results}}.
#'     \item \code{periods}: The period specification passed in.
#'     \item \code{call}: The matched call.
#'   }
#'
#' @details
#' The bootstrap procedure resamples topic-relevant sentences with
#' replacement within each period across \code{n_bootstrap} iterations,
#' computing frame similarity at each iteration to produce an empirical
#' distribution of frame strength estimates. Sentence embeddings are
#' pre-computed and fixed across bootstrap iterations; only the
#' resampling indices vary. This makes 10,000 iterations computationally
#' feasible on standard hardware.
#'
#' The permutation test assesses whether the observed between-period
#' difference in mean frame similarity is distinguishable from chance
#' under the null hypothesis of no difference. It operates on the
#' bootstrap distributions rather than raw sentence-level scores.
#'
#' Relative emphasis scores normalize frame similarities within each
#' bootstrap iteration so that scores across categories sum to one,
#' enabling within-period comparison of relative frame dominance.
#' Absolute similarity scores should not be compared across frame
#' categories directly.
#'
#' @seealso \code{\link{plot.frameR_results}},
#'   \code{\link{embed_corpus}},
#'   \code{\link{identify_topic_sentences}},
#'   \code{\link{embed_keywords}}
#'
#' @examples
#' \dontrun{
#' model <- load_model()
#'
#' # Embed corpus
#' embeddings <- embed_corpus(my_corpus$text, model)
#'
#' # Identify topic sentences
#' topic_mask <- identify_topic_sentences(
#'   sentences    = my_corpus$text,
#'   embeddings   = embeddings,
#'   anchor_words = c("immigration", "immigrant", "migration"),
#'   model        = model
#' )
#'
#' # Specify and embed frame categories
#' frame_categories <- list(
#'   Economic = c("economy", "jobs", "welfare", "employment"),
#'   Cultural = c("culture", "values", "identity", "tradition"),
#'   Security = c("crime", "border", "terrorism", "security")
#' )
#' keyword_embeddings <- embed_keywords(frame_categories, model)
#'
#' # Measure frames
#' results <- measure_frames(
#'   embeddings        = embeddings,
#'   topic_mask        = topic_mask,
#'   keyword_embeddings = keyword_embeddings,
#'   periods           = list(Early = c(1997, 2011),
#'                            Late  = c(2012, 2022)),
#'   years             = my_corpus$year
#' )
#'
#' print(results)
#' plot(results)
#' }
#'
#' @export
measure_frames <- function(embeddings,
                           topic_mask,
                           keyword_embeddings,
                           periods,
                           years,
                           n_bootstrap    = 10000L,
                           n_permutations = 10000L,
                           seed           = 42L) {

  check_python_env()

  # Input validation
  if (!is.matrix(embeddings)) {
    stop("embeddings must be a matrix returned by embed_corpus().",
         call. = FALSE)
  }

  if (!is.logical(topic_mask)) {
    stop("topic_mask must be a logical vector returned by ",
         "identify_topic_sentences().",
         call. = FALSE)
  }

  if (length(topic_mask) != nrow(embeddings)) {
    stop(
      "topic_mask length (", length(topic_mask), ") must equal ",
      "nrow(embeddings) (", nrow(embeddings), ").",
      call. = FALSE
    )
  }

  if (length(years) != nrow(embeddings)) {
    stop(
      "years length (", length(years), ") must equal ",
      "nrow(embeddings) (", nrow(embeddings), ").",
      call. = FALSE
    )
  }

  if (!is.list(periods) || is.null(names(periods))) {
    stop("periods must be a named list.", call. = FALSE)
  }

  if (length(periods) != 2) {
    stop(
      "Exactly 2 periods are required for permutation testing. ",
      "Received: ", length(periods),
      call. = FALSE
    )
  }

  period_names <- names(periods)
  all_summaries <- list()
  all_boot_results <- list()
  all_ratio_summaries <- list()

  # Process each period
  for (period_name in period_names) {

    year_range <- periods[[period_name]]

    period_mask <- topic_mask &
      years >= year_range[1] &
      years <= year_range[2]

    n_sentences <- sum(period_mask)

    if (n_sentences == 0) {
      stop(
        "No topic-relevant sentences found in period '",
        period_name, "' (", year_range[1], "-", year_range[2], "). ",
        "Check your periods specification and topic_mask.",
        call. = FALSE
      )
    }

    message(
      "\nPeriod '", period_name, "' (",
      year_range[1], "-", year_range[2], "): ",
      n_sentences, " topic-relevant sentences."
    )

    period_embeddings <- embeddings[period_mask, , drop = FALSE]

    message("Running bootstrap (", n_bootstrap, " iterations)...")

    boot_results <- pkg_env$bootstrap_frames(
      doc_embeddings     = period_embeddings,
      keyword_embeddings = keyword_embeddings,
      n_boot             = as.integer(n_bootstrap),
      seed               = as.integer(seed)
    )

    summary <- pkg_env$summarise_bootstrap(
      boot_results = boot_results,
      period_name  = period_name
    )

    ratio_results <- pkg_env$compute_ratios(
      boot_results = boot_results
    )

    ratio_summary <- pkg_env$summarise_ratios(
      ratio_results = ratio_results,
      period_name   = period_name
    )

    all_summaries[[period_name]]      <- summary_to_dataframe(summary)
    all_boot_results[[period_name]]   <- boot_results
    all_ratio_summaries[[period_name]] <- summary_to_dataframe(ratio_summary)
  }

  # Separate variance from frame summaries
  # Separate variance from frame summaries
  combined_summary <- do.call(rbind, all_summaries) %>%
    dplyr::filter(.data$frame != "frame_variance")

  variance_summary <- do.call(rbind, all_summaries) %>%
    dplyr::filter(.data$frame == "frame_variance") %>%
    dplyr::select(.data$period, .data$mean, .data$sd,
                  .data$ci_lower, .data$ci_upper)

  combined_ratios <- do.call(rbind, all_ratio_summaries) %>%
    dplyr::filter(.data$frame != "frame_variance")

  rownames(combined_summary)  <- NULL
  rownames(variance_summary)  <- NULL
  rownames(combined_ratios)   <- NULL
  # Permutation tests between the two periods
  message("\nRunning permutation tests (", n_permutations, " draws)...")


  perm_results <- pkg_env$permutation_test(
    boot_results_1 = all_boot_results[[period_names[1]]],
    boot_results_2 = all_boot_results[[period_names[2]]],
    n_permutations = as.integer(n_permutations),
    seed           = as.integer(seed)
  )

  perm_df <- summary_to_dataframe(perm_results)
  rownames(perm_df) <- NULL

  # Permutation test for frame variance
  var_period_1 <- all_boot_results[[period_names[1]]][["frame_variance"]]
  var_period_2 <- all_boot_results[[period_names[2]]][["frame_variance"]]

  observed_var_diff <- mean(var_period_2) - mean(var_period_1)
  pooled_var        <- c(var_period_1, var_period_2)
  n1_var            <- length(var_period_1)

  set.seed(seed)
  perm_var_diffs <- replicate(n_permutations, {
    shuffled <- sample(pooled_var)
    mean(shuffled[seq_len(n1_var)]) -
      mean(shuffled[(n1_var + 1):length(shuffled)])
  })

  var_p_value <- mean(abs(perm_var_diffs) >= abs(observed_var_diff))

  var_perm_row <- data.frame(
    frame        = "frame_variance",
    difference   = observed_var_diff,
    p_value      = var_p_value,
    significance = dplyr::case_when(
      var_p_value < 0.001 ~ "***",
      var_p_value < 0.01  ~ "**",
      var_p_value < 0.05  ~ "*",
      TRUE                ~ "ns"
    )
  )

  perm_df <- rbind(perm_df, var_perm_row)

  # Assemble results object
  results <- structure(
    list(
      summary           = combined_summary,
      variance          = variance_summary,
      permutation_tests = perm_df,
      ratios            = combined_ratios,
      boot_results      = all_boot_results,
      periods           = periods,
      call              = match.call()
    ),
    class = "frameR_results"
  )

  message("\nDone. Use print() or plot() to inspect results.")

  return(results)
}


#' Print method for frameR_results
#'
#' @param x A \code{frameR_results} object.
#' @param ... Additional arguments (ignored).
#' @export
#' @export
print.frameR_results <- function(x, ...) {

  cat("\n=== frameR Results ===\n\n")

  cat("Periods:\n")
  for (nm in names(x$periods)) {
    cat("  ", nm, ": ",
        x$periods[[nm]][1], "-", x$periods[[nm]][2], "\n",
        sep = "")
  }

  cat("\nFrame Similarity (Bootstrap Estimates):\n")
  print(
    x$summary[, c("period", "frame", "mean",
                  "ci_lower", "ci_upper")],
    row.names = FALSE,
    digits    = 4
  )

  cat("\nFrame Variance (Bootstrap Estimates):\n")
  cat("Higher values indicate more concentrated framing\n")
  cat("around a dominant category.\n\n")
  print(
    x$variance[, c("period", "mean", "ci_lower", "ci_upper")],
    row.names = FALSE,
    digits    = 6
  )

  cat("\nBetween-Period Differences (Permutation Tests):\n")
  print(
    x$permutation_tests[, c("frame", "difference",
                            "p_value", "significance")],
    row.names = FALSE,
    digits    = 4
  )

  cat("\nRelative Frame Emphasis:\n")
  print(
    x$ratios[, c("period", "frame", "mean_ratio",
                 "ci_lower", "ci_upper")],
    row.names = FALSE,
    digits    = 4
  )

  invisible(x)
}
