#' Download files published on gov.uk publications 
#' \url{https://www.gov.uk/government/publications}
#' 
#' @param directory Specify directory for download
#' @param type file type of downloaded documents. See \code{\link{download_pages}}
#'  for retrieving page source.
#' \describe{
#' \item{all}{(default) do not pre-filter on file type}
#' \item{csv}{}
#' \item{pdf}{}
#' }
#' 
#' @export
download_files <- function(directory, type = c("all", "csv", "pdf")) {
  type <- match.arg(type)
  
  repeat {
    src <- .govenv$driver$getPageSource()
    res <- parse_results(src)
    urls <- unlist(lapply(res, parse_links, type))
    invisible(lapply(urls, function(x) download(directory, x)))
    
    # check whether there are more pages
    nextpage <- get_next_page()
    if (identical(nextpage, FALSE)) {
      break
    }
  }
}

#' Download the HTML source of pages published on gov.uk publications
#' \url{https://www.gov.uk/government/publications}
#' 
#' @export
download_pages <- function() {
  repeat {
    src <- .govenv$driver$getPageSource()
    res <- parse_results(src)
    txts <- vapply(res, RCurl::getURL, character(1))
    
    pages <- character()
    pages <- c(pages, vapply(txts, get_html_body))
    
    nextpage <- get_next_page()
    if (identical(nextpage, FALSE)) {
      break
    }
  }
  pages
}

download <- function(directory, url) {
  # create directory if it doesn't exist
  if (!dir.exists(directory)) {
    message(sprintf("Creating directory at %s", directory))
    dir.create(directory, recursive = TRUE)
  }
  
  path <- unlist(strsplit(url, "/"))
  filename <- path[length(path)]
  filepath <- file.path(directory, filename)
  url <- paste0(BASEURL, url)
  utils::download.file(url, filepath)
}

get_next_page <- function() {
  # Could be implemented with an XML search
  xpath <- paste(c("//nav[@id='show-more-documents']",
                   "ul[@class='previous-n
                   ext-navigation']",
                   "li[@class='next']",
                   "a"), collapse = "/")
  nextpage <- tryCatch(.govenv$driver$findElement("xpath", xpath),
                       error = function(e) e)
  if (!inherits(nextpage, "error")) {
    nextpage$clickElement()
    TRUE
  }
  else {
    FALSE
  }
}

parse_results <- function(src) {
  body <- get_html_body(src)
  xpath <- "//div[contains(@class,'filter-results')]"
  res <- XML::getNodeSet(body, xpath)
  xpath <- ".//li[@class='document-row']//a"
  urls <- unlist(lapply(res,
                        function(x) XML::xpathSApply(x, xpath,
                                                     XML::xmlGetAttr, name = "href")))
  # TODO: add organisation names to return
  xpath <- ".//li[@class='document-row']//li[@class='organisations']"
  orgs <- unlist(lapply(res,
                        function(x) XML::xpathSApply(x, xpath, XML::xmlValue)))
  urls
}

parse_links <- function(url, type = c("all", "csv", "pdf")) {
  type <- match.arg(type)
  
  url <- paste0(BASEURL, url)
  txt <- RCurl::getURL(url)
  body <- get_html_body(txt)
  xpath <- "//section[@class='attachment embedded']"
  attaches <- XML::getNodeSet(body, xpath)
  
  if (type == "csv") {
    # exclude preview links
    xpath <- paste(c("./div[@class='attachment-details']",
                   "a[contains(@href, '.csv') and not(contains(@href, 'preview'))]"),
                   collapse = "//")
  }
  else if (type == "pdf") {
    xpath <- paste(c("./div[@class='attachment-details']",
                     "a[contains(@href, '.pdf') and not(contains(@href, 'preview'))]"),
                   collapse = "//")
  }
  else {
    xpath <- paste(c("./div[@class='attachment-details']",
                     "a[not(contains(@href, 'preview'))]"),
                   collapse = "//")
  }
  urls <- unlist(lapply(attaches,
                        function(x) XML::xpathSApply(x, xpath,
                                                     XML::xmlGetAttr, name = "href")))
  urls
}
