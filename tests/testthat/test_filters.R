context("Filters are working")

caps <- list(chromeOptions = list(args = c("--headless", "--disable-gpu")))
start_browser(port = 4447L,
              docker = FALSE,
              browser = "chrome",
              verbose = FALSE,
              check = TRUE,
              extraCapabilities = caps)
main_page()
on.exit(stop_browser())

test_that("Filters can be obtained", {
  f <- get_filters()
  expect_identical(length(f), 5L)
})

test_that("XML names can be obtained with 'field' argument", {
  f <- get_filters(field = "value")
  expect_identical(length(unlist(f)), 8L)
})

test_that("Human-readable names can be obtained with 'field' argument", {
  f <- get_filters(field = "descriptors")
  expect_identical(length(unlist(f)), 8L)
})

test_that("Filtering through menu works", {
  expect_silent(use_filter("closed-consultations"))
})

test_that("Filter application through keywords search works", {
  expect_silent(use_filter("meetings", filter_type = "keywords"))
})

test_that("Filter application through date (from) search works", {
  expect_silent(use_filter("01/01/2018", filter_type = "from_date"))
})

test_that("Filter application through date (to) search works", {
  expect_silent(use_filter("01/01/2018", filter_type = "to_date"))
})
