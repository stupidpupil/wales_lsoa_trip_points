# osmium tags-filter wales_ish.osm.pbf na/place n/ahighway=bus_stop na/railway=halt na/railway=station na/amenity=pub --overwrite -o wales_ish.places.osm.pbf
# OSM_CONFIG_FILE=osmconf.ini ogr2ogr wales_ish.places.gpkg wales_ish.places.osm.pbf

library(tidyverse)
library(sf)

boundaries <- st_read("data-raw/Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Super_Generalised_Clipped_(BSC)_EW_V3.geojson") %>%
  filter(LSOA11CD %>% str_detect("^W"))

centroids <- st_read("data-raw/Lower_Layer_Super_Output_Areas_(December_2011)_Population_Weighted_Centroids.geojson") %>%
  filter(lsoa11cd %>% str_detect("^W")) %>%
  rename(LSOA11CD = lsoa11cd)

unlink("data/lsoa11_centroids.geojson")
centroids %>% select(LSOA11CD) %>%
  st_write("data/lsoa11_centroids.geojson")


places_from_areas <- st_read("data-raw/wales_ish.places.gpkg", layer='multipolygons') %>%
  st_point_on_surface() %>% select(-any_of(c('osm_way_id')))

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
    )
  ) %>%
  st_join(boundaries)

#
# For any LSOA11 that's 
# - got at least one LOC or COM, and
# - is bigger than the 66th percentile
# we'll use the most central LOC or COM we can find
#

lsoa11cds_that_should_use_nearest_place <- places %>%
  filter(!is.na(LSOA11CD)) %>%
  select(LSOA11CD, Shape__Area) %>% as_tibble() %>%
  group_by(LSOA11CD) %>% slice(1L) %>%
  filter(Shape__Area > quantile(boundaries$Shape__Area, 0.66)) %>%
  pull(LSOA11CD)

possible_places <- places %>% 
  filter(LSOA11CD %in% lsoa11cds_that_should_use_nearest_place)

centroids_for_distances <- possible_places %>%
  select(LSOA11CD) %>% st_drop_geometry() %>% 
  left_join(centroids, by='LSOA11CD')

st_geometry(centroids_for_distances) <- centroids_for_distances$geometry

possible_places$distance_to_lsoa11_centroid <- 
  possible_places %>%
  st_distance(centroids_for_distances, by_element=TRUE)

chosen_places <- possible_places %>%
  group_by(LSOA11CD) %>% arrange(LSOA11CD, distance_to_lsoa11_centroid) %>% slice(1L) %>% 
  mutate(distance_to_lsoa11_centroid_metres = as.integer(distance_to_lsoa11_centroid)) %>%
  rename(place_name = name) %>%
  select(LSOA11CD, place_type, place_name, distance_to_lsoa11_centroid_metres) %>% rename(geometry=geom)

#
# For the remaining LSOAs, we just use the centroid
#

centroids_for_remaining_lsoas <- centroids %>%
  filter(!(LSOA11CD %in% chosen_places$LSOA11CD)) %>%
  mutate(
    place_type = 'Population-weighted centroid',
    distance_to_lsoa11_centroid_metres = 0L, place_name=NA_character_) %>%
  select(LSOA11CD, place_type, place_name, distance_to_lsoa11_centroid_metres)

st_geometry(centroids_for_remaining_lsoas) <- centroids_for_remaining_lsoas$geometry

lsoa_place_points <- chosen_places %>% rbind(centroids_for_remaining_lsoas)
stopifnot(nrow(lsoa_place_points) == 1909)

unlink("data/lsoa11_place_points.geojson")
lsoa_place_points %>% st_write("data/lsoa11_place_points.geojson")
