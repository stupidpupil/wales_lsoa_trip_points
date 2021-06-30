library(tidyverse)
library(sf)

boundaries <- st_read("data-raw/Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Super_Generalised_Clipped_(BSC)_EW_V3.geojson") %>%
  filter(LSOA11CD %>% str_detect("^W"))

centroids <- st_read("data-raw/Lower_Layer_Super_Output_Areas_(December_2011)_Population_Weighted_Centroids.geojson") %>%
  filter(lsoa11cd %>% str_detect("^W")) %>%
  rename(LSOA11CD = lsoa11cd)

places <- read_csv("data-raw/Index_of_Place_Names_in_Great_Britain_(July_2016).csv") %>%
  filter(ctry15nm == 'Wales') %>%
  filter(descnm %in% c('LOC', 'COM')) %>%
  group_by(place15cd) %>% slice(1L) %>% ungroup %>%
  st_as_sf(coords = c('long_', 'lat'), crs=4326) %>%
  st_join(boundaries)

#
# Overrides
#

overrides <- read_csv('data-raw/overrides.csv')

overrides <- overrides %>%
  st_as_sf(coords = c('lon', 'lat'), crs=4326) %>%
  mutate(place15cd = NA_character_, place15nm = NA_character_)

centroids_for_distances <- overrides %>%
  select(LSOA11CD) %>% st_drop_geometry() %>% 
  left_join(centroids, by='LSOA11CD')

st_geometry(centroids_for_distances) <- centroids_for_distances$geometry

overrides$distance_to_lsoa11_centroid <- 
  overrides %>%
  st_distance(centroids_for_distances, by_element=TRUE)

overrides <- overrides %>%
  mutate(distance_to_lsoa11_centroid_metres = as.integer(distance_to_lsoa11_centroid)) %>%
  select(LSOA11CD, place15cd, place15nm, distance_to_lsoa11_centroid_metres)

#
# For any LSOA11 that's 
# - got at least one LOC or COM, and
# - is bigger than the median LSOA11
# we'll use the most central LOC or COM we can find
#

lsoa11cds_that_should_use_nearest_place <- places %>%
  filter(!is.na(LSOA11CD)) %>%
  filter(!(LSOA11CD %in% overrides$LSOA11CD)) %>%
  select(LSOA11CD, Shape__Area) %>% as_tibble() %>%
  group_by(LSOA11CD) %>% slice(1L) %>%
  filter(Shape__Area > quantile(boundaries$Shape__Area, 0.5)) %>%
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
  select(LSOA11CD, place15cd, place15nm, distance_to_lsoa11_centroid_metres)


#
# For the remaining LSOAs, we just use the centroid
#

centroids_for_remaining_lsoas <- centroids %>%
  filter(!(LSOA11CD %in% union(chosen_places$LSOA11CD, overrides$LSOA11CD))) %>%
  mutate(place15cd = NA_character_, place15nm = NA_character_, distance_to_lsoa11_centroid_metres = 0L) %>%
  select(LSOA11CD, place15cd, place15nm, distance_to_lsoa11_centroid_metres) %>%
  as_tibble

st_geometry(centroids_for_remaining_lsoas) <- centroids_for_remaining_lsoas$geometry


lsoa_trip_points <- overrides %>% rbind(chosen_places) %>% rbind(centroids_for_remaining_lsoas)
stopifnot(nrow(lsoa_trip_points) == 1909)
unlink("data/lsoa11_trip_points.geojson")
lsoa_trip_points %>% st_write("data/lsoa11_trip_points.geojson")
