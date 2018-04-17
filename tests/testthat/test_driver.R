context("Minimum functionality of the WebDriver")

test_that("Browser (default, Chrome) can be initiated", {
  caps <- list(chromeOptions = list(args = c("--headless", "--disable-gpu")))
  start_browser(docker = FALSE,
                browser = "chrome",
                verbose = FALSE,
                check = TRUE,
                extraCapabilities = caps)
  expect_true(exists("driver", where = .govenv))
  expect_true(exists("server", where = .govenv))
  stop_browser()
})

test_that("Firefox can be initiated", {
  start_browser(docker = FALSE,
                browser = "firefox",
                verbose = TRUE,
                check = TRUE)
  expect_true(exists("driver", where = .govenv))
  expect_true(exists("server", where = .govenv))
  stop_browser()
})

# test_that("PhantomJS can be initiated", {
#   start_browser(docker = FALSE,
#                 browser = "phantomjs",
#                 verbose = FALSE,
#                 check = TRUE)
#   expect_true(exists("driver", where = .govenv))
#   expect_true(exists("server", where = .govenv))
#   stop_browser()
# })

test_that("Docker can be used", {
  id <- system2("docker",
                args = c("run", "-d", "-p", "4445:4444 selenium/standalone-firefox:3.10.0"),
                stdout = TRUE)
  start_browser(port = 4445L, docker = TRUE)
  expect_true(exists("driver", where = .govenv))
  system2("docker", args = c("kill", id), stdout = FALSE)
  stop_browser()
})

test_that("Browser is able to navigate to the main page", {
  caps <- list(chromeOptions = list(args = c("--headless", "--disable-gpu")))
  start_browser(docker = FALSE,
                browser = "chrome",
                verbose = FALSE,
                check = TRUE,
                extraCapabilities = caps)
 main_page()
 title <- unlist(get_title())
 expect_identical(title, "Publications - GOV.UK")
 stop_browser()
})
