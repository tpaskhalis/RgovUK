context("Search results can be downloaded")

caps <- list(chromeOptions = list(args = c("--headless", "--disable-gpu")))
start_browser(port = 4448L,
              docker = FALSE,
              browser = "chrome",
              verbose = FALSE,
              check = TRUE,
              extraCapabilities = caps)
main_page()
on.exit(stop_browser())

test_that("Files can be downloaded", {
  temp <- tempdir()
  download_files(temp, limit = 10, type = "csv")
  fls <- list.files(temp)
  pdffls <- fls[tools::file_ext(fls) == "pdf"]
  expect_identical(length(pdffls), 10L)
})

test_that("HTML source can be downloaded", {
  pages <- download_html(limit = 10)
  expect_identical(length(pages), 10L)
})
