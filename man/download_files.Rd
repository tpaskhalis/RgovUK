% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download.R
\name{download_files}
\alias{download_files}
\alias{govuk_download_files}
\title{Download gov.UK publications}
\usage{
download_files(directory, limit = NULL, type = c("all", "csv", "xls",
  "pdf"))

govuk_download_files(directory, limit = NULL, type = c("all", "csv", "xls",
  "pdf"))
}
\arguments{
\item{directory}{Specify directory for download}

\item{limit}{Numeric value, setting the limit of the number of downloaded files,
NULL (all files that meet the criteria) by default}

\item{type}{File type of downloaded documents. See \code{\link{download_html}}
 for retrieving page source.
\describe{
\item{all}{(default) download comma-separated values(.csv), Excel(.xls} or Adobe Acrobat(.pdf) files
\item{csv}{Download only CSV files}
\item{xls}{Download only XLS files}
\item{pdf}{Download only PDF files}
}}
}
\description{
Download files published on
\href{https://www.gov.uk/government/publications}{gov.uk publications}
}
\examples{
\dontrun{
download_files(tempdir(), limit = 10, type = "csv")
}

}
\author{
Tom Paskhalis
}
