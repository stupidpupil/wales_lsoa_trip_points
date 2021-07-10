library(tidyverse)
library(sf)

test_lsoa_trip_points <- function(){

  java_args = function(){
    c("--add-opens", "java.base/java.io=ALL-UNNAMED", "--add-opens", "java.base/java.util=ALL-UNNAMED", "-Xmx8g")
  }

  launch_otp <- function(){

    start_program <- function(command, args, message, timeout = 5, ...) {
      timeout <- as.difftime(timeout, units = "secs")
      deadline <- Sys.time() + timeout
      px <- processx::process$new(command, args, stdout = "|", ...)
      while (px$is_alive() && (now <- Sys.time()) < deadline) {
        poll_time <- as.double(deadline - now, units = "secs") * 1000
        px$poll_io(as.integer(poll_time))
        lines <- px$read_output_lines()
        if (any(grepl(message, lines))) return(px)
      }

      px$kill()
      stop("Cannot start ", command)
    }

    px <- start_program(
      "java", c(java_args(), "-jar","../wales_ish_otp_graph/data-raw/otp.jar", "--load", "../wales_ish_otp_graph/output"), 
      "Started listener bound to \\[0.0.0.0:8080\\]", timeout=240)

    close(px$get_output_connection())

    return(px)
  }

  otp_route_request_url <- function(fromLat, fromLon, toLat, toLon, when, public){

    mode <- ifelse(public, "TRANSIT%2CWALK", "CAR")

    paste0("http://zenit:8080/otp/routers/default/plan?",
      "fromPlace=", fromLat, "%2C", fromLon,
      "&toPlace=", toLat, "%2C", toLon,
      "&time=", when %>% strftime("%H%%3A%M%%3A%S"),
      "&date=",when %>% strftime("%Y-%m-%d"),
      "&mode=", mode, 
      "&maxWalkDistance=", 5000.0, 
      "&arriveBy=false&wheelchair=false&debugItineraryFilter=false&locale=en&maxItineraries=1")
  }


  initialise_test_journeys_tibble <- function(){
    when = lubridate::now() %>% (function(x){x - lubridate::wday(x) + lubridate::days(1)}) %>% update(hour=11, minute=0, second = 0)
    
  trip_points <- st_read("data/lsoa11_nearest_road_points.geojson")
  trip_points <- trip_points %>% 
    mutate(Lon = st_coordinates(.)[,'X'], Lat= st_coordinates(.)[,'Y']) %>% 
    st_drop_geometry() %>% tibble() %>%
    select(LSOA11CD, Lat, Lon)


  trip_points %>% head(955) %>% rename_all(function(x){paste0("from", x)}) %>% 
    bind_cols(trip_points %>% tail(955) %>% rename_all(function(x){paste0("to", x)})) %>%
      crossing(expand_grid(when=when, public=c(T,F))) %>%
      mutate(requestUrl = otp_route_request_url(fromLat, fromLon, toLat, toLon, when, public))
  }

  print("here")

  #px <- launch_otp()

  try_to_get_response <- function(requestUrl){
    tryCatch({
      return(read_file(requestUrl))
    }, error=function(err){})
    return(NA_character_)
  }

  journeys <- initialise_test_journeys_tibble()
  journeys <- journeys %>% rowwise() %>% mutate(otpResponse = try_to_get_response(requestUrl)) %>% ungroup()
  #px$kill()

  journeys %>% write_csv("data/test_journeys.csv")

  try_to_parse_response <- function(otp_response){
    tryCatch({
      return(list(jsonlite::fromJSON(otp_response)))
    }, error=function(err){})
    return(list(NULL))
  }

  try_to_get_duration <- function(otp_response_json){
    if(is.null(otp_response_json)){
      return(NA_integer_)
    }

    tryCatch({
      return(otp_response_json$plan$itineraries[[1, 'duration']])
    }, error=function(err){})
    return(NA_integer_)
  }

  journeys <- journeys %>% rowwise() %>% 
    mutate(
      otpResponseJson = try_to_parse_response(otpResponse), 
      durationSeconds = try_to_get_duration(otpResponseJson),
      otpResponseJson = NULL) %>% ungroup()

  journeys %>% write_csv("data/test_journeys.csv")
}