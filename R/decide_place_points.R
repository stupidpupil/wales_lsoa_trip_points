decide_place_points <- function(){

  boundaries <- st_read("data-raw/lsoa21_boundaries_subset.geojson")

  centroids <- st_read("data-raw/lsoa21_centroids.geojson") %>%
    filter(LSOA21CD %in% boundaries$LSOA21CD) %>%
    rename(LSOA21CD = LSOA21CD)

  unlink("output/lsoa21_centroids.geojson")
  centroids %>% select(LSOA21CD) %>%
    st_write("output/lsoa21_centroids.geojson")

  print("Producing places.gpkg…")

  osmium_command = paste0(
    "osmium tags-filter ",
    " data-raw/wales_ish.osm.pbf",
    " na/place n/ahighway=bus_stop na/railway=halt na/railway=station na/amenity=pub",
    " --overwrite -o data-raw/wales_ish.places.osm.pbf"
  )
  system(osmium_command)

  unlink("data-raw/wales_ish.places.gpkg")
  ogr2ogr_command = paste0(
    "ogr2ogr ",
    " data-raw/wales_ish.places.gpkg",
    " data-raw/wales_ish.places.osm.pbf"
  )

  Sys.setenv(OSM_CONFIG_FILE = "data-raw/osmconf.ini")
  system(ogr2ogr_command)


  places_from_areas <- st_read("data-raw/wales_ish.places.gpkg", layer='multipolygons') %>%
    st_point_on_surface() %>% select(-any_of(c('osm_way_id')) )

  places <- (places_from_areas %>% rbind(st_read("data-raw/wales_ish.places.gpkg", layer='points'))) %>%
    filter(
      place %in% c('village', 'town', 'suburb', 'quarter') |
      highway %in% c('bus_stop') |
      railway %in% c('halt', 'station') |
      amenity %in% c('pub'),
      is.na(usage) | usage != 'tourism' # Try to exclude tourist railways
    ) %>% 
    mutate(
      place_type = case_when(
        highway == 'bus_stop' ~ 'Bus stop',
        !is.na(railway) ~ 'Railway station',
        amenity == 'pub' ~ 'Pub',
        TRUE ~ str_to_title(place)
      ),

      distance_multiplier = case_when(
        place_type == 'Pub' ~ 2.0,
        place_type == 'Bus stop' ~ 0.95,
        place_type == 'Railway station' ~ 0.95,
        place_type %in% c('Town', 'Suburb', 'Quarter') ~ 0.75,
        TRUE ~ 1.0
      )
    ) %>%
    st_join(boundaries)

  #
  # For any LSOA11 that's 
  # - got at least one LOC or COM, and
  # - is bigger than the 66th percentile
  # we'll use the most central LOC or COM we can find
  #

  lsoa21cds_that_should_use_nearest_place <- places %>%
    filter(!is.na(LSOA21CD)) %>%
    select(LSOA21CD, SHAPE_Area) %>% as_tibble() %>%
    group_by(LSOA21CD) %>% slice(1L) %>%
    filter(SHAPE_Area > quantile(boundaries$SHAPE_Area, 0.66)) %>%
    pull(LSOA21CD)

  possible_places <- places %>% 
    filter(LSOA21CD %in% lsoa21cds_that_should_use_nearest_place)

  centroids_for_distances <- possible_places %>%
    select(LSOA21CD) %>% st_drop_geometry() %>% 
    left_join(centroids, by='LSOA21CD')

  st_geometry(centroids_for_distances) <- centroids_for_distances$geometry

  possible_places$distance_to_lsoa21_centroid <- 
    possible_places %>%
    st_distance(centroids_for_distances, by_element=TRUE)

  possible_places <- possible_places %>% 
    mutate(adjusted_distance = distance_multiplier * distance_to_lsoa21_centroid)

  chosen_places <- possible_places %>%
    group_by(LSOA21CD) %>% arrange(LSOA21CD, adjusted_distance) %>% slice(1L) %>% 
    mutate(distance_to_lsoa21_centroid_metres = as.integer(distance_to_lsoa21_centroid)) %>%
    rename(place_name = name) %>%
    select(LSOA21CD, place_type, place_name, distance_to_lsoa21_centroid_metres) %>% rename(geometry=geom)

  #
  # For the remaining LSOAs, we just use the centroid
  #

  centroids_for_remaining_lsoas <- centroids %>%
    filter(!(LSOA21CD %in% chosen_places$LSOA21CD)) %>%
    mutate(
      place_type = 'Population-weighted centroid',
      distance_to_lsoa21_centroid_metres = 0L, place_name=NA_character_) %>%
    select(LSOA21CD, place_type, place_name, distance_to_lsoa21_centroid_metres)

  st_geometry(centroids_for_remaining_lsoas) <- centroids_for_remaining_lsoas$geometry

  lsoa_place_points <- chosen_places %>% rbind(centroids_for_remaining_lsoas)
  stopifnot(nrow(lsoa_place_points) == nrow(centroids))

  unlink("output/lsoa21_place_points.geojson")
  lsoa_place_points %>% st_write("output/lsoa21_place_points.geojson")

}