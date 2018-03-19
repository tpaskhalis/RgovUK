% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download_govuk.R
\name{download_files}
\alias{download_files}
\title{Download files published on gov.uk publications 
\url{https://www.gov.uk/government/publications}}
\usage{
download_files(directory, type = c("all", "csv", "pdf"))
}
\arguments{
\item{directory}{Specify directory for download}

\item{type}{file type of downloaded documents. See \code{\link{download_pages}}
 for retrieving page source.
\describe{
\item{all}{(default) do not pre-filter on file type}
\item{csv}{}
\item{pdf}{}
}}
}
\description{
Download files published on gov.uk publications 
\url{https://www.gov.uk/government/publications}
}