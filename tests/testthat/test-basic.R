# tests/testthat/test-basic.R
# Basic sanity checks for frameR

test_that("frameR loads without error", {
  expect_true(is.environment(pkg_env))
})

test_that("frame_categories_to_python validates input correctly", {

  # Valid input should pass through
  valid <- list(
    Economic = c("economy", "jobs"),
    Cultural = c("culture", "values")
  )
  expect_equal(frame_categories_to_python(valid), valid)

  # Non-list input should error
  expect_error(
    frame_categories_to_python(c("economy", "jobs")),
    "must be a named list"
  )

  # Unnamed list should error
  expect_error(
    frame_categories_to_python(list(c("economy"), c("culture"))),
    "must be a named list"
  )
})

test_that("summary_to_dataframe converts correctly", {

  test_list <- list(
    list(period = "Early", frame = "Economic",
         mean = 0.4, sd = 0.01,
         ci_lower = 0.38, ci_upper = 0.42, n_boot = 100),
    list(period = "Early", frame = "Cultural",
         mean = 0.3, sd = 0.01,
         ci_lower = 0.28, ci_upper = 0.32, n_boot = 100)
  )

  result <- summary_to_dataframe(test_list)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true("period" %in% names(result))
  expect_true("frame" %in% names(result))
  expect_true("mean" %in% names(result))
})
