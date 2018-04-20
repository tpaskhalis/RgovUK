#' Download gov.UK publications
#' 
#' Download files published on
#' \href{https://www.gov.uk/government/publications}{gov.uk publications}
#'
#' @param directory Specify directory for download
#' @param limit Numeric value, setting the limit of the number of downloaded files,
#' NULL (all files that meet the criteria) by default
#' @param type File type of downloaded documents. See \code{\link{download_html}}
#'  for retrieving page source.
#' \describe{
#' \item{all}{(default) do not pre-filter on file type}
#' \item{csv}{Download only CSV files}
#' \item{pdf}{Download only PDF files}
#' }
#'
#' @examples
#' \dontrun{
#' download_files(tempdir(), limit = 10, type = "csv")
#' }
#'
#' @author Tom Paskhalis
#' @export
download_files <- function(directory,
                           limit = NULL,
                           type = c("all", "csv", "pdf")) {
  type <- match.arg(type)
  
  check_browser()
  
  num <- 0
  repeat {
    src <- unlist(.govenv$driver$getPageSource())
    res <- parse_results(src)
    urls <- unlist(lapply(res, parse_links, type))
    
    if (!is.null(limit)) {
      if ((num + length(urls)) >= limit) {
      top <- num + limit
      urls <- urls[seq(1, top)]
    }
    num <- num + length(urls)
    }
    
    invisible(lapply(urls, function(x) download(directory, x)))
    
    if (!is.null(limit) && num >= limit) {
      break
    }
    
    # check whether there are more pages
    nextpage <- get_next_page()
    if (identical(nextpage, FALSE)) {
      break
    }
  }
}

#' Download the HTML source of pages published on
#' \href{https://www.gov.uk/government/publications}{gov.uk publications}
#'
#' @param limit Numeric value, setting the limit of the number of downloaded pages,
#' NULL (all pages that meet the criteria) by default
#'
#' @examples
#' \dontrun{
#' # download HTML source code of search results
#' p <- download_html(limit = 10)
#' }
#'
#' @author Tom Paskhalis
#' @export
download_html <- function(limit = NULL) {
  check_browser()
  
  num <- 0
  html <- character()
  repeat {
    src <- unlist(.govenv$driver$getPageSource())
    urls <- parse_results(src)
    
    if (!is.null(limit)) {
      if ((num + length(urls)) >= limit) {
        top <- num + limit
        urls <- urls[seq(1, top)]
      }
      num <- num + length(urls)
    }
    
    txts <- unlist(lapply(lapply(urls, httr::GET),
                          httr::content, type = "text", encoding = "UTF-8"))
    html <- c(html, txts)
    # txts <- vapply(urls, RCurl::getURL, character(1))
    
    if (!is.null(limit) && num >= limit) {
      break
    }
    
    nextpage <- get_next_page()
    if (identical(nextpage, FALSE)) {
      break
    }
  }
  html
}

download <- function(directory, url) {
  # create directory if it doesn't exist
  if (!dir.exists(directory)) {
    print(sprintf("Creating directory at %s", directory))
    dir.create(directory, recursive = TRUE)
  }
  
  path <- unlist(strsplit(url, "/"))
  filename <- path[length(path)]
  filepath <- file.path(directory, filename)
  parsed <- httr::parse_url(url)
  if (is.null(parsed$scheme) || parsed$scheme %in% c("https", "http", "ftp")) {
    if (is.null(parsed$hostname)) {
      url <- paste0(BASEURL, url)
    }
    curl::curl_download(url, filepath)
  } else {
    message(sprintf("The link %s is not a valid http link", url))
  }
}

get_next_page <- function(src) {
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
  } else {
    FALSE
  }
}

parse_results <- function(src) {
  body <- get_html_body(src)
  xpath <- "//div[contains(@class,'js-filter-results')]"
  res <- XML::getNodeSet(body, xpath)
  xpath <- ".//li[@class='document-row']/h3/a"
  urls <- unlist(lapply(res,
                        function(x) XML::xpathSApply(x, xpath,
                                                     XML::xmlGetAttr, name = "href")))
  # # TODO: add organisation names to return
  # xpath <- ".//li[@class='document-row']//li[@class='organisations']"
  # orgs <- unlist(lapply(res,
  #                       function(x) XML::xpathSApply(x, xpath, XML::xmlValue)))
  urls <- vapply(urls, function(x) paste0(BASEURL, x), character(1))
  urls
}

parse_links <- function(url, type = c("all", "csv", "pdf")) {
  type <- match.arg(type)
  
  txt <- httr::content(httr::GET(url), type = "text", encoding = "UTF-8")
  body <- get_html_body(txt)
  xpath <- "//section[@class='attachment embedded']"
  attaches <- XML::getNodeSet(body, xpath)
  
  if (type == "csv") {
    # exclude preview links
    xpath <- paste(c("./div[@class='attachment-details']",
                   "a[contains(@href, '.csv') and not(contains(@href, 'preview'))]"),
                   collapse = "//")
  } else if (type == "pdf") {
    xpath <- paste(c("./div[@class='attachment-details']",
                     "a[contains(@href, '.pdf') and not(contains(@href, 'preview'))]"),
                   collapse = "//")
  } else {
    xpath <- paste(c("./div[@class='attachment-details']",
                     "a[not(contains(@href, 'preview'))]"),
                   collapse = "//")
  }
  urls <- unlist(lapply(attaches,
                        function(x) XML::xpathSApply(x, xpath,
                                                     XML::xmlGetAttr, name = "href")))
  urls
}

#' @rdname download_files
#' @export
govuk_download_files <- download_files

#' @rdname download_html
#' @export
govuk_download_html <- download_html
