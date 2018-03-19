# create environment for Selenium driver
.govenv <- new.env()

#' Start Selenium driver 
#' 
#' \code{start_browser} should be run before execution of other functions in the
#' package. Selenium driver is required for both application of filters and 
#' parsing results. Further documentation is available in \code{\link[RSelenium]{rsDriver}}.
#' 
#' @param port Port to use
#' @param browser Which browser should be used
#' \describe{
#' \item{\code{"chrome"}}{}
#' \item{\code{"firefox"}}{}
#' \item{\code{"phantomjs"}}{}
#' \item{\code{"internet explorer"}}{}
#' }
#' @param verbose Print out messages
#' 
#' @export
start_browser <- function(port = 4567L,
                          browser = c("chrome",
                                      "firefox",
                                      "phantomjs",
                                      "internet explorer"),
                          verbose = TRUE) {
  browser <- match.arg(browser)
  
  driver <- RSelenium::rsDriver(port = port, browser = browser, verbose = verbose)
  assign("driver", driver[["client"]], envir = .govenv)
}

#' Open main page of gov.UK publications
#' \url{https://www.gov.uk/government/publications}
#' 
#' @export
main_page <- function() {
  if (!exists("driver", where = .govenv)) {
    stop("Browser instance could not be found. Try, running start_browser() first")
  }
  url <- paste0(BASEURL, PUBLICATIONS)
  .govenv$driver$navigate(url)
}