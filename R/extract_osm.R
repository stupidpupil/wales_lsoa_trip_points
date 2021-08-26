extract_osm <- function(){

  osmium_command = paste0(
    "osmium extract -p data-raw/wales_ish_bbox.geojson",
    " -s smart ",
    " data-raw/great-britain-latest.osm.pbf",
    " -o data-raw/wales_ish.osm.pbf"
  )

  system(osmium_command)

}