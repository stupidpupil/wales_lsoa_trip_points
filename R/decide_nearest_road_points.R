# osmium tags-filter wales_ish.osm.pbf w/highway --overwrite -f pbf,add_metadata=false -o wales_ish.ways.osm.pbf 
# OSM_CONFIG_FILE=osmconf.ini ogr2ogr wales_ish.ways.gpkg wales_ish.ways.osm.pbf

decide_nearest_road_points <- function(){

  print("Producing ways.gpkg")

  osmium_command = paste0(
    "osmium tags-filter ",
    " data-raw/wales_ish.osm.pbf",
    " w/highway",
    " --overwrite -f pbf,add_metadata=false -o data-raw/wales_ish.ways.osm.pbf"
  )
  system(osmium_command)

  unlink("data-raw/wales_ish.ways.gpkg")


  # GeoJSON is inefficient
  # but GDAL seems more reliably happy to write it
  ogr2ogr_command = paste0(
    "ogr2ogr ",
    " -oo INTERLEAVED_READING=YES",
    " data-raw/wales_ish.ways.geojson",
    " data-raw/wales_ish.ways.osm.pbf lines"
  )
  Sys.setenv(OSM_CONFIG_FILE = "data-raw/osmconf.ini")
  system(ogr2ogr_command)


  ways <- st_read("data-raw/wales_ish.ways.geojson")

  unusable_tags <- c('proposed', 'construction', 'no', 'raceway')

  ways <- ways %>% filter(!(highway %in% unusable_tags))

  road_tags <- c(
    'trunk', 'primary', 'secondary',
    'tertiary', 'unclassified',
    'residential')

  road_tags <- c(road_tags, paste0(road_tags, '_link'))

  roads <- ways %>% 
    filter(highway %in% road_tags)


  roads <- roads %>%
    filter(tunnel != "yes" | is.na(tunnel))

  lsoa_place_points <- st_read("output/lsoa21_place_points.geojson")

  nearest_line <- st_nearest_feature(lsoa_place_points, roads)
  nearest_line <- roads[nearest_line,] %>% mutate(
    road_name = case_when(
      is.na(name) & is.na(ref) ~ NA_character_,
      is.na(ref) ~ name,
      is.na(name) ~ ref,
      TRUE ~ paste0(name, ' (', ref, ')')
    ))

  nearest_points <- 1:nrow(lsoa_place_points) %>% 
    map(function(i){st_nearest_points(lsoa_place_points[i,], nearest_line[i,])[[1]]}) %>% 
    st_as_sfc

  nearest_points <- (nearest_points %>% st_cast("LINESTRING") %>% st_cast("POINT"))[1:(nrow(lsoa_place_points))*2]

  lsoa_trip_points <- lsoa_place_points
  st_geometry(lsoa_trip_points) <- nearest_points
  st_crs(lsoa_trip_points) <- st_crs(nearest_line)
  lsoa_trip_points$road_name <- nearest_line$road_name

  centroids <- st_read("output/lsoa21_centroids.geojson")

  lsoa_trip_points <- lsoa_trip_points %>% arrange(LSOA21CD)
  centroids <- centroids %>% arrange(LSOA21CD)

  lsoa_trip_points$distance_to_lsoa21_centroid_metres <- st_distance(lsoa_trip_points, centroids, by_element=TRUE) %>% as.integer()

  unlink("output/lsoa21_nearest_road_points.geojson")
  lsoa_trip_points %>% st_write("output/lsoa21_nearest_road_points.geojson")
}
