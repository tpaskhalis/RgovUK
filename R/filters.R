#' Get all document search filters applicable to government publications
#'
#' \code{get_filters} parses the filter options available for selecting
#' government publicattions. The current options include: keyword search,
#' publication type, policy area, department, official document status,
#' world locations, date of publication (before/after).
#' 
#' @param field specifies the parameter of filter that should be returned, has
#' to be one of:
#' \describe{
#' \item{\code{"all"}}{(default) both attributes and descriptors, 
#' as well as possible options for filters with drop-down menus}
#' \item{\code{"values"}}{XML tag attributes that can be passed to browser}
#' \item{\code{"descriptors"}}{description that can be
#' viewed on the website by the enduser, text contained in the XML tag}
#' }
#' 
#' @return list with fields specified in the arguments
#' 
#' @examples 
#' \dontrun{
#' filters <- get_filters()
#' head(as.data.frame(filters))
#' }
#' 
#' @author Tom Paskhalis
#' @export
get_filters <- function(field = c("all", "values", "descriptors")) {
  field <- match.arg(field)
  
  check_browser()
  
  url <- paste0(BASEURL, PUBLICATIONS)
  .govenv$driver$navigate(url)
  src <- .govenv$driver$getPageSource()
  filters <- parse_filters(src, field = field)
  filters
}

#' Filter publications based on selection criteria
#' 
#' @param selection Must be either a value that defines option from a drop-down
#' menu (retrieved with \link{get_filters}) or a text to be inserted in search
#' bar (keyword or date ranges)
#' @param filter_type Type of filter to which the selection is applied 
#' (drop-down menu by default)
#' 
#' @examples
#' \dontrun{
#' use_filter("close-consultations")
#' use_filter("01/01/2018", filter_type = "from_date")
#' }
#' 
#' @author Tom Paskhalis
#' @export 
use_filter <- function(selection,
                       filter_type = c("menu",
                                       "keywords",
                                       "from_date",
                                       "to_date")) {
  type <- match.arg(filter_type)
  
  check_browser()
  
  if (!is.character(selection)) {
    stop(paste0("Selection must be character ",
                "(either drop-down option or search/date entry"))
  }
  
  if (type == "menu") {
    xpath <- paste(c("//form[@id='document-filter']",
                     "fieldset",
                     "div[contains(@class,'filter')]/",
                     sprintf("option[@value='%s']", selection)
                     ), collapse = "/")
    filter <- .govenv$driver$findElement("xpath", xpath)
    filter$clickElement()
  } else {
    xpath <- paste(c("//form[@id='document-filter']",
                     "fieldset",
                     "div[contains(@class,'filter')]/",
                     sprintf("input[@name='%s']", filter_type)
                     ), collapse = "/")
    filter <- .govenv$driver$findElement("xpath", xpath)
    filter$sendKeysToElement(list(selection))
  }
}

# Parse block with document search filters.
# returns XML labels, text visible to user and options for drop-down menus
parse_filters <- function(src, field = c("values", "descriptors", "all")) {
  body <- get_html_body(src)
  xpath <- paste(c("//form[@id='document-filter']",
                   "fieldset",
                   "div[contains(@class,'filter')]",
                   "label"
                   ), collapse = "/")
  filters <- XML::getNodeSet(body, xpath)
  # values <- lapply(filters,
  #                  function(x) XML::getNodeSet(x, "./label/@for"))
  # descriptors <- lapply(filters,
  #                       function(x) XML::getNodeSet(x, "./label/text()"))
  values <- unlist(lapply(filters, function(x) XML::xmlGetAttr(x, name = "for")))
  txts <- unlist(lapply(filters, function(x) XML::xmlValue(x)))
  if (field == "values") {
    lst <- list(values = values)
    lst
  } else if (field == "descriptors") {
    lst <- list(descriptors = txts)
    lst
  } else if (field == "all") {
    opts <- lapply(filters, parse_filter_options, field = "all")
    # opt.values and opt.descriptors are assumed to be of equal length,
    # TODO: might be worth just looking at the ancestor of a tag
    lens <- unlist(lapply(lapply(opts, `[[`, 1), length))
    values <- list(values = rep(values, times = lens))
    txts <- list(txts = rep(txts, times = lens))
    # zip (as in Python) opts
    opts[["f"]] <- list
    opts <- do.call(Map, opts)
    opts <- lapply(opts, unlist)
    lst <- c(values, descriptors = txts, opts)
    lst
  }
}

parse_filter_options <- function(node,
                                 field = c("all", "values", "descriptors")) {
  checkopts <- XML::getNodeSet(node, "./following-sibling::select")
  if (length(checkopts) == 0) {
    values <- NA
    txts <- NA
    groups <- NA
  } else {
    checkgrps <- XML::getNodeSet(node, "..//optgroup")
    if (length(checkgrps) == 0) {
      values <- unlist(XML::xpathSApply(node, "..//option",
                                        XML::xmlGetAttr, name = "value"))
      txts <- unlist(XML::xpathSApply(node, "..//option", XML::xmlValue))
      groups <- rep(NA, times = length(values))
    } else {
      opts <- XML::getNodeSet(node, "..//option")
      values <- lapply(opts, function(x) XML::xmlGetAttr(x, name = "value"))
      txts <- lapply(opts, function(x) XML::xmlValue(x))
      groups <- lapply(opts, function(x) XML::xpathSApply(x, "..", XML::xmlGetAttr, name = "label"))
      # get rid of nested structures around NULL
      groups <- lapply(groups, unlist)
      # replace options outside of optgroups with NA
      groups <- Map(function(x, y) ifelse(length(x) == length(y), x, NA), groups, values)
      values <- unlist(values)
      txts <- unlist(txts)
      groups <- unlist(groups)
    }
  }
  if (field == "all") {
    lst <- list(opt.groups = groups,
                opt.values = values,
                opt.descriptors = txts)
    lst
  } else if (field == "values") {
    values
  } else if (field == "descriptors") {
    txts
  }
}

get_html_body <- function(src) {
  tree <- XML::htmlParse(src, asText = TRUE)
  root <- XML::xmlRoot(tree)
  root[["body"]]
}

#' @rdname get_filters
#' @export
govuk_get_filters <- get_filters

#' @rdname use_filter
#' @export
govuk_use_filter <- use_filter
