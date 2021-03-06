% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download.R
\name{download_html}
\alias{download_html}
\alias{govuk_download_html}
\title{Download the HTML source of pages published on
\href{https://www.gov.uk/government/publications}{gov.uk publications}}
\usage{
download_html(limit = NULL)

govuk_download_html(limit = NULL)
}
\arguments{
\item{limit}{Numeric value, setting the limit of the number of downloaded pages,
NULL (all pages that meet the criteria) by default}
}
\description{
Download the HTML source of pages published on
\href{https://www.gov.uk/government/publications}{gov.uk publications}
}
\examples{
\dontrun{
# download HTML source code of search results
p <- download_html(limit = 10)
}

}
\author{
Tom Paskhalis
}
