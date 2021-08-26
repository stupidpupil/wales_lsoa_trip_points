download_osm <- function(){
  old_timeout <- getOption('timeout')
  options(timeout=600)
  gb_osm_url <- "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf"
  dest_path <- "data-raw/great-britain-latest.osm.pbf"
  download.file(gb_osm_url, dest_path)
  options(timeout = old_timeout)
}