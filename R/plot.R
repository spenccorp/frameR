#' @importFrom rlang .data
NULL

# frameR/R/plot.R
# Visualization functions for frameR results

#' Plot frame similarity results
#'
#' Produces a set of diagnostic and results plots for a
#' \code{frameR_results} object. By default produces three panels:
#' absolute frame similarity by period, relative frame emphasis
#' by period, and between-period differences with significance.
#'
#' @param x A \code{frameR_results} object returned by
#'   \code{\link{measure_frames}}.
#' @param type Character. One of \code{"all"}, \code{"similarity"},
#'   \code{"ratios"}, or \code{"differences"}. Default \code{"all"}.
#' @param ... Additional arguments (ignored).
#'
#' @return Called for its side effects. Produces a plot.
#'
#' @examples
#' \dontrun{
#' results <- measure_frames(...)
#' plot(results)
#' plot(results, type = "differences")
#' }
#'
#' @export
plot.frameR_results <- function(x, type = "all", ...) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "ggplot2 is required for plotting. ",
      "Install it with: install.packages('ggplot2')",
      call. = FALSE
    )
  }

  type <- match.arg(type, c("all", "similarity",
                            "ratios", "differences"))

  period_names <- names(x$periods)

  # --------------------------------------------------------
  # Plot 1: Absolute frame similarity by period
  # --------------------------------------------------------

  p1 <- ggplot2::ggplot(
    x$summary,
    ggplot2::aes(
      x     = .data$frame,
      y     = .data$mean,
      ymin  = .data$ci_lower,
      ymax  = .data$ci_upper,
      fill  = .data$period,
      group = .data$period
    )
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_dodge(width = 0.6),
      width    = 0.5,
      alpha    = 0.85
    ) +
    ggplot2::geom_errorbar(
      position = ggplot2::position_dodge(width = 0.6),
      width    = 0.2
    ) +
    ggplot2::labs(
      title = "Absolute Frame Similarity by Period",
      x     = "Frame Category",
      y     = "Mean Cosine Similarity",
      fill  = "Period"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )

  # --------------------------------------------------------
  # Plot 2: Relative frame emphasis by period
  # --------------------------------------------------------

  p2 <- ggplot2::ggplot(
    x$ratios,
    ggplot2::aes(
      x     = .data$frame,
      y     = .data$mean_ratio,
      ymin  = .data$ci_lower,
      ymax  = .data$ci_upper,
      fill  = .data$period,
      group = .data$period
    )
  ) +
    ggplot2::geom_col(
      position = ggplot2::position_dodge(width = 0.6),
      width    = 0.5,
      alpha    = 0.85
    ) +
    ggplot2::geom_errorbar(
      position = ggplot2::position_dodge(width = 0.6),
      width    = 0.2
    ) +
    ggplot2::labs(
      title = "Relative Frame Emphasis by Period",
      x     = "Frame Category",
      y     = "Proportion of Total Frame Similarity",
      fill  = "Period"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title      = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )

  # --------------------------------------------------------
  # Plot 3: Between period differences with significance
  # --------------------------------------------------------

  diff_data <- x$permutation_tests
  diff_data$label <- paste0(
    round(diff_data$difference, 4),
    " (", diff_data$significance, ")"
  )
  diff_data$positive <- diff_data$difference > 0

  p3 <- ggplot2::ggplot(
    diff_data,
    ggplot2::aes(
      x    = .data$difference,
      y    = .data$frame,
      fill = .data$positive
    )
  ) +
    ggplot2::geom_col(alpha = 0.85, width = 0.5) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = .data$significance,
        x     = .data$difference +
          ifelse(.data$positive, 0.0005, -0.0005)
      ),
      hjust = ifelse(diff_data$positive, 0, 1),
      size  = 4
    ) +
    ggplot2::geom_vline(
      xintercept = 0,
      linetype   = "dashed",
      linewidth  = 0.5
    ) +
    ggplot2::scale_fill_manual(
      values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
      guide  = "none"
    ) +
    ggplot2::labs(
      title   = paste0(
        "Between-Period Differences\n(",
        period_names[2], " \u2212 ", period_names[1], ")"
      ),
      x       = "Change in Cosine Similarity",
      y       = "Frame Category",
      caption = "*** p<0.001  ** p<0.01  * p<0.05  ns = not significant"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title   = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(hjust = 0)
    )

  # --------------------------------------------------------
  # Return requested plots
  # --------------------------------------------------------

  if (type == "similarity") {
    print(p1)
  } else if (type == "ratios") {
    print(p2)
  } else if (type == "differences") {
    print(p3)
  } else {

    if (!requireNamespace("patchwork", quietly = TRUE)) {
      message(
        "Install patchwork for combined plots: ",
        "install.packages('patchwork'). ",
        "Printing plots separately."
      )
      print(p1)
      print(p2)
      print(p3)
    } else {
      combined <- (p1 | p2) / p3
      print(combined)
    }
  }

  invisible(x)
}
