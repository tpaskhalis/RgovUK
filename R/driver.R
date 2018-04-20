# create environment for Selenium driver
.govenv <- new.env()

#' Start Selenium driver 
#' 
#' \code{start_browser} should be run before execution of other functions in the
#' package. Selenium driver is required for both application of filters and 
#' parsing results. Further documentation is available in \code{\link[RSelenium]{rsDriver}}.
#' 
#' @param port Port to use
#' @param docker Specify whether instead of launching its own server,
#' Docker container is runninng and can be connected to.
#' @param browser Which browser should be used
#' \describe{
#' \item{\code{"chrome"}}{}
#' \item{\code{"firefox"}}{}
#' \item{\code{"phantomjs"}}{}
#' \item{\code{"internet explorer"}}{}
#' }
#' @param verbose Print out messages
#' @param check Check the version of Selenium and associated drivers
#' @param extraCapabilities Optional arguments (browser-specific)
#' 
#' @export
start_browser <- function(port = 4445L,
                          docker = TRUE,
                          browser = c("chrome",
                                      "firefox",
                                      "phantomjs",
                                      "internet explorer"),
                          verbose = TRUE,
                          check = TRUE,
                          extraCapabilities = list()) {
  if (docker) {
    message("Connecting to Docker container...")
    driver <- RSelenium::remoteDriver(port = port)
    driver$open()
    assign("docker", docker, envir = .govenv)
    assign("driver", driver, envir = .govenv)
  } else {
    browser <- match.arg(browser)
    
    # Workaround for RSelenium/issues/150
    if (browser == "phantomjs") {
      vers <- unlist(binman::list_versions("seleniumserver"))
      vers <- vers[vers %in% c("3.0.1", "3.5.3")]
      driver <- RSelenium::rsDriver(port = port,
                                    browser = browser,
                                    version = vers[1],
                                    verbose = verbose,
                                    check = check,
                                    extraCapabilities = extraCapabilities)
    } else {
      driver <- RSelenium::rsDriver(port = port,
                                    browser = browser,
                                    verbose = verbose,
                                    check = check,
                                    extraCapabilities = extraCapabilities)
    }
    
    # driver[["client"]]$setTimeout(type = "page load", milliseconds = 10000)
    # driver[["client"]]$setTimeout(type = "script", milliseconds = 10000)
    # driver[["client"]]$setTimeout(type = "implicit", milliseconds = 10000)
    
    assign("docker", FALSE, envir = .govenv)
    assign("driver", driver[["client"]], envir = .govenv)
    assign("server", driver[["server"]], envir = .govenv)
  }
}

#' Stop Selenium driver
#' 
#' @export
stop_browser <- function() {
  if (exists("driver", where = .govenv)) {
    message("Terminating browser...")
    docker <- get("docker", envir = .govenv)
    if (docker) {
      .govenv$driver$closeServer()
    } else {
      .govenv$driver$close()
      .govenv$server$stop()
    }
  }
}

#' Open main page of gov.UK publications
#' \url{https://www.gov.uk/government/publications}
#' 
#' @export
main_page <- function() {
  check_browser()
  
  url <- paste0(BASEURL, PUBLICATIONS)
  .govenv$driver$navigate(url)
}

get_title <- function() {
  url <- paste0(BASEURL, PUBLICATIONS)
  title <- .govenv$driver$getTitle(url)
  title
}

check_browser <- function() {
  if (!exists("driver", where = .govenv)) {
    stop("Browser instance could not be found. Try, running start_browser() first")
  }
}
