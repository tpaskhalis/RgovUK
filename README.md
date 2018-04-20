# RgovUK
An R package for downloading data from the [gov.UK publications](https://www.gov.uk/government/publications)

## Introduction

This package is designed to automate the download of documents from the main
repository of documents on the official UK government website. Unfortunately, 
no API is currently available and the datasets available on [data.gov.uk](https://data.gov.uk)
provide only a subset of information
that is published by the government departments and agencies. On top of that, the
website uses JavaScript which prevents from using simpler RCurl-based scrapers.
Thus, this package has to rely on a less-then-ideal approach of using [RSelenium](https://github.com/ropensci/RSelenium),
R bindings for Selenium WebDriver. This solution is not as stable it would have 
been with RESTful API or static website, due to a larger number of moving parts,
but it's the only way to automate the arduous task of pointing and clicking
on the official website if you have to collect more than a handful of documents.

## Installation

This package is, for now, only available on GitHub and can be installed by running:

```
devtools::install_github("tpaskhalis/RgovUK")
```

## Setting Up RSelenium

The primary depedency is [RSelenium](https://github.com/ropensci/RSelenium)
package that allows to run headless browser and normal browser on headless server.
`RgovUK` allows both internal launch of a browser or connecting to an
existing Docker instance. With the second, Docker, approach being the preferred
one, due to higher stability. See [RSelenium: Docker Containers](http://rpubs.com/johndharrison/RSelenium-Docker)
vignette for more details on how to set up Docker for `RSelenium`.

## Using RgovUK

Before any functionality of the package can be used, the broswer needs to be
intantiated:

```
start_browser()
```

Or, if the approach with Docker is used:

```
start_browser(port = 4445L, docker = TRUE)
```

Where `port` should correspond to the host port that used to map the container port. E.g. `docker run -d -p 4445:4444 selenium/standalone-firefox:3.10.0` maps container port 4444 to the host port 4445.

After the browser is launched, it should be pointed to the [main page](https://www.gov.uk/government/publications) of the
website by running:

```
main_page()
```

The website contains two key fields: filters and results.

![](http://i.imgur.com/95Dls1z.png)

## Filters

`get_filters` and `use_filters` are the two function for retrieving the available
filters and applying them to narrow down the required documents.

```
f <- get_filters(field = "descriptors")
# f
# $descriptors
# [1] "Contains"                 "Publication type"         "Policy area"              "Department"   
# [5] "Official document status" "World locations"          "Published after"          "Published before"
```

```
filters <- get_filters()
head(as.data.frame(filters))
#                      values descriptors.txts    opt.groups           opt.values       opt.descriptors
# 1                  keywords         Contains          <NA>                 <NA>                  <NA>
# 2 publication_filter_option Publication type          <NA>                  all All publication types
# 3 publication_filter_option Publication type Consultations        consultations     All consultations
# 4 publication_filter_option Publication type Consultations closed-consultations  Closed consultations
# 5 publication_filter_option Publication type Consultations   open-consultations    Open consultations
# 6 publication_filter_option Publication type     Corporate    corporate-reports     Corporate reports
```

```
departments <- as_data_frame(filters) %>%
  filter(opt.groups == "Ministerial departments") %>%
  select(opt.values) %>%
  unlist()
```

```
use_filter(departments[1])
use_filter("meetings", filter_type = "text")
```

## Results

To download the documents that match the filter criteria as described above,
the package contains two functions: `download_files` and `download_html`.
The former allows to download the files the links to which are listed on the
pages that are listed as search results. The latter downloads the pages themselves.
This can be particularly useful, when the document search criteria are more 
complicated than the filter functionality of the website allows to apply.
Or, when the meta information about the files is required.

```
temp <- tempdir()
download_files(temp, limit = 10, type = "csv")
```
