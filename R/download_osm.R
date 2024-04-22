download_osm <- function(){
  old_opts <- options(timeout=6000)
  on.exit(options(old_opts))
  gb_osm_url <- "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf"
  dest_path <- "data-raw/great-britain-latest.osm.pbf"
  download.file(gb_osm_url, dest_path)
}
