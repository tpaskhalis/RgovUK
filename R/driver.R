create_driver <- function(port = 4567L,
                          browser = c("chrome",
                                      "firefox",
                                      "phantomjs",
                                      "internet explorer"),
                          verbose = TRUE) {
  browser <- match.arg(browser)
  
  driver <- RSelenium::rsDriver(port = port, browser = browser, verbose = verbose)
  driver <- driver[["client"]]
  driver
}