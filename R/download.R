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
#' \item{all}{(default) download comma-separated values(.csv), Excel(.xls} or Adobe Acrobat(.pdf) files
#' \item{csv}{Download only CSV files}
#' \item{xls}{Download only XLS files}
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
                           type = c("all", "csv", "xls", "pdf")) {
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
    print(sprintf("Downloading %s from %s", filename, url))
    curl::curl_download(url, filepath)
  } else {
    message(sprintf("The link %s is not a valid http link", url))
  }
}

get_next_page <- function() {
  xpath <- paste(c("//nav[@id='show-more-documents']",
                   "ul[@class='previous-next-navigation']",
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
  urls <- vapply(urls, function(x) paste0(BASEURL, x), character(1))
  urls
}

parse_links <- function(url, type) {
  txt <- httr::content(httr::GET(url), type = "text", encoding = "UTF-8")
  body <- get_html_body(txt)
  xpath <- "//section[@class='attachment embedded']"
  attaches <- XML::getNodeSet(body, xpath)
  
  if (type == "csv") {
    # exclude preview links
    xpath <- paste(c("./div[@class='attachment-details']",
                     sprintf("a[%s and %s]",
                             "contains(@href, '.csv')",
                             "not(contains(@href, 'preview'))")),
                   collapse = "//")
  } else if (type == "xls") {
    xpath <- paste(c("./div[@class='attachment-details']",
                     sprintf("a[%s and %s]",
                             "contains(@href, '.xls')",
                             "not(contains(@href, 'preview'))")),
                   collapse = "//")
  } else if (type == "pdf") {
    xpath <- paste(c("./div[@class='attachment-details']",
                     sprintf("a[%s and %s]",
                             "contains(@href, '.pdf')",
                             "not(contains(@href, 'preview'))")),
                   collapse = "//")
  } else {
    xpath <- paste(c("./div[@class='attachment-details']",
                     sprintf("a[(%s) and %s]",
                             paste(c("contains(@href, '.csv')",
                                     "contains(@href, '.xls')",
                                     "contains(@href, '.pdf')"),
                                   collapse = " or "),
                             "not(contains(@href, 'preview'))")),
                   collapse = "//")
  }
  urls <- unlist(lapply(attaches,
                        function(x) XML::xpathSApply(x, xpath,
                                                     XML::xmlGetAttr, name = "href")))
  if (!all(is.null(urls))) {
    # Check file extensions of extracted urls
    paths <- unlist(lapply(lapply(urls, httr::parse_url), `[[`, "path"))
    splitpaths <- strsplit(paths, split = "/")
    fls <- unlist(lapply(splitpaths, tail, n = 1))
    exts <- vapply(fls, tools::file_ext, character(1))
    if (type == "csv") {
      links <- urls[exts == "csv"]
    } else if (type == "xls") {
      links <- urls[exts == "xls"]
    } else if (type == "pdf") {
      links <- urls[exts == "pdf"]
    } else {
      links <- urls
    }
    links
  } else {
    NULL
  }
}

#' @rdname download_files
#' @export
govuk_download_files <- download_files

#' @rdname download_html
#' @export
govuk_download_html <- download_html
