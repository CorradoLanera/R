#' COVID-19 Data Hub
#'
#' Unified dataset for a better understanding of COVID-19. Collects COVID-19 data across governmental sources. 
#' Includes policy measures from \href{https://www.bsg.ox.ac.uk/covidtracker}{Oxford COVID-19 Government Response Tracker}. 
#' Extends the dataset via an interface to 
#' \href{https://data.worldbank.org/}{World Bank Open Data}, 
#' \href{https://www.google.com/covid19/mobility/}{Google Mobility Reports}, 
#' \href{https://www.apple.com/covid19/mobility}{Apple Mobility Reports}.
#'
#' @param country vector of country names or \href{https://github.com/covid19datahub/COVID19/blob/master/inst/extdata/db/ISO.csv}{ISO codes} (alpha-2, alpha-3 or numeric).
#' @param level integer. Granularity level. 1: country-level data. 2: state-level data. 3: lower-level data.
#' @param start the start date of the period of interest.
#' @param end the end date of the period of interest.
#' @param vintage logical. Retrieve the snapshot of the dataset that was generated at the \code{end} date instead of using the latest version. Default \code{FALSE}.
#' @param raw logical. Skip data cleaning? Default \code{FALSE}. See details.
#' @param wb character vector of \href{https://data.worldbank.org}{World Bank} indicator codes. See details.
#' @param gmr url to the \href{https://www.google.com/covid19/mobility/}{Google Mobility Report} dataset. See details.
#' @param amr url to the \href{https://www.apple.com/covid19/mobility}{Apple Mobility Report} dataset. See details.
#' @param cache logical. Memory caching? Significantly improves performance on successive calls. Default \code{TRUE}.
#' @param verbose logical. Print data sources? Default \code{TRUE}. 
#'
#' @details 
#' If \code{raw=TRUE}, the raw data are cleaned by filling missing dates with \code{NA} values. 
#' This ensures that all locations share the same grid of dates and no single day is skipped. 
#' Then, \code{NA} values are replaced with the previous non-\code{NA} value or \code{0}.
#' 
#' The dataset can be extended with \href{https://data.worldbank.org}{World Bank Open Data} via the argument \code{wb}, a character vector of indicator codes.
#' The codes can be found by inspecting the corresponding URL. For example, the code of the GDP indicator available at \url{https://data.worldbank.org/indicator/NY.GDP.MKTP.CD} is \code{NY.GDP.MKTP.CD}.
#' The latest data available between the \code{start} and \code{end} date are downloaded.
#'
#' The dataset can be extended with \href{https://www.google.com/covid19/mobility/}{Google Mobility Reports} via the argument \code{gmr}, the url to the Google CSV file.
#' At the time of writing, the CSV is available at \href{https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv}{this link}. 
#' 
#' The dataset can be extended with \href{https://www.apple.com/covid19/mobility}{Apple Mobility Reports} via the argument \code{amr}, the url to the Apple CSV file.
#' At the time of writing, the CSV is available at \href{https://covid19-static.cdn-apple.com/covid19-mobility-data/2008HotfixDev28/v2/en-us/applemobilitytrends-2020-05-15.csv}{this link}.
#'
#' Data sources are stored in the \code{src} attribute. See examples.
#'
#' @return Grouped \code{tibble} (\code{data.frame}). See the \href{https://covid19datahub.io/articles/doc/data.html}{dataset description}
#'
#' @examples
#' \dontrun{
#'
#' # Worldwide data by country
#' x <- covid19()
#'
#' # Worldwide data by state
#' x <- covid19(level = 2)
#'
#' # Specific country data by city
#' x <- covid19(c("Italy","US"), level = 3)
#' 
#' # Merge with World Bank data
#' wb <- c("gdp" = "NY.GDP.MKTP.CD", "hosp_beds" = "SH.MED.BEDS.ZS")
#' x  <- covid19(wb = wb)
#' 
#' # Merge with Google Mobility Reports
#' gmr <- "https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv"
#' x   <- covid19(gmr = gmr)
#' 
#' # Merge with Apple Mobility Reports
#' amr <- "https://covid19-static.cdn-apple.com/covid19-mobility-data/"
#' amr <- paste0(amr, "2009HotfixDev19/v3/en-us/applemobilitytrends-2020-06-03.csv")
#' x   <- covid19(amr = amr)
#' 
#' # Data sources
#' s <- attr(x, "src")
#' }
#'
#' @source \url{https://covid19datahub.io}
#'
#' @references 
#' Guidotti, E., Ardia, D., (2020), "COVID-19 Data Hub", Working paper, \doi{10.13140/RG.2.2.11649.81763}.
#'
#' @note 
#' We have invested a lot of time and effort in creating \href{https://covid19datahub.io}{COVID-19 Data Hub}, please:
#' 
#' \itemize{
#' \item cite \href{https://www.researchgate.net/publication/340771808_COVID-19_Data_Hub}{Guidotti and Ardia (2020)} in working papers and published papers that use it.
#' \item place the URL \url{https://covid19datahub.io} in a footnote to help others find \href{https://covid19datahub.io}{COVID-19 Data Hub}.
#' \item you assume full risk for the use of \href{https://covid19datahub.io}{COVID-19 Data Hub}. 
#' We try our best to guarantee the data quality and consistency and the continuous filling of the Data Hub. 
#' However, it is free software and comes with ABSOLUTELY NO WARRANTY. 
#' Reliance on \href{https://covid19datahub.io}{COVID-19 Data Hub} for medical guidance or use of \href{https://covid19datahub.io}{COVID-19 Data Hub} in commerce is strictly prohibited.
#' }
#' 
#' @export
#'
covid19 <- function(country = NULL,
                    level   = 1,
                    start   = "2010-01-01",
                    end     = Sys.Date(),
                    raw     = FALSE,
                    vintage = FALSE,
                    verbose = TRUE,
                    cache   = TRUE,
                    wb      = NULL,
                    gmr     = NULL,
                    amr     = NULL){

  # fallback
  if(!(level %in% 1:3))
    stop("valid options for 'level' are:
         1: admin area level 1
         2: admin area level 2
         3: admin area level 3")

  # cache
  cachekey <- make.names(sprintf("covid19_%s_%s_%s_%s_%s_%s_%s",paste0(country, collapse = "."), level, ifelse(vintage, end, 0), raw, ifelse(is.null(wb),"",paste(wb, collapse = "")), ifelse(is.null(gmr),"",gmr), ifelse(is.null(amr),"",amr)))
  if(cache & exists(cachekey, envir = cachedata)){
    x <- get(cachekey, envir = cachedata) 
    return(x[x$date >= start & x$date <= end,])
  }

  # data
  x    <- data.frame()
  url  <- "https://storage.covid19datahub.io"
  name <- sprintf("%sdata-%s", ifelse(raw, 'raw', ''), level)
  
  # latest
  if(!vintage){
    
    zip  <- sprintf("%s/%s.zip", url, name) 
    file <- sprintf("%s.csv", name) 
    
    x   <- read.zip(zip, file, cache = cache)[[1]]
    src <- read.csv(sprintf("%s/src.csv", url), cache = cache)
    
  }
  # vintage
  else {
    
    if(end < "2020-04-14")
      stop("vintage data not available before 2020-04-14")
    if(end > Sys.Date()-2)
      stop(sprintf("vintage data not available on %s", end))
    
    zip          <- sprintf("%s/%s.zip", url, end)
    files        <- c(paste0("data-",1:3,".csv"), paste0("rawdata-",1:3,".csv"), "src.csv")
    names(files) <- gsub("\\.csv$", "", files)
    
    x <- read.zip(zip, files, cache = cache)
    
    src <- x[["src"]]
    x   <- x[[name]]
    
  }
  
  # filter
  if(length(country <- toupper(country)) > 0){
    
    id <- iso_alpha_3 <- iso_alpha_2 <- iso_numeric <- administrative_area_level_1 <- NA
    x  <- dplyr::filter(x, toupper(id) %in% country | iso_alpha_3 %in% country | iso_alpha_2 %in% country | iso_numeric %in% country | toupper(administrative_area_level_1) %in% country)
    
  }

  # check
  if(nrow(x)==0)
    return(NULL)
  
  # date
  x$date <- as.Date(x$date)
  
  # world bank
  if(!is.null(wb))
    x <- worldbank(x, indicator = wb, start = start, end = end)
  
  # google mobility
  if(!is.null(gmr))
    x <- google(x, level = level, url = gmr, cache = cache)
  
  # apple mobility
  if(!is.null(amr))
    x <- apple(x, level = level, url = amr, cache = cache)
  
  # group and order
  x <- x %>%
    dplyr::group_by(id) %>%
    dplyr::arrange(id, date)

  # src
  attr(x, "src") <- try(cite(x, src, verbose = verbose))
  
  # cache
  if(cache)
    assign(cachekey, x, envir = cachedata)

  # return
  return(x[x$date >= start & x$date <= end,])

}
