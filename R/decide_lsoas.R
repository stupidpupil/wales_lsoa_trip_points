decide_lsoas <- function(){
  sf_use_s2(FALSE)
  lsoa21_boundaries <- st_read("data-raw/lsoa21_boundaries.geojson") %>%
    select(LSOA21CD, SHAPE_Area)

  area_of_interest <- st_read("data-raw/area_of_interest.geojson")

  lsoa21_boundaries <- lsoa21_boundaries[area_of_interest, , op=st_intersects]

  # Remove any islands
  touching_any_others <- lsoa21_boundaries %>% st_touches(lsoa21_boundaries, sparse=FALSE) %>% apply(1, any)
  lsoa21_boundaries <- lsoa21_boundaries[touching_any_others, ]

  #Require that we have all Welsh LSOAs
  stopifnot(lsoa21_boundaries %>% filter(LSOA21CD %>% str_detect("^W")) %>% nrow() == 1917)

  unlink("data-raw/lsoa21_boundaries_subset.geojson")
  lsoa21_boundaries %>% st_write("data-raw/lsoa21_boundaries_subset.geojson")


  unlink("data-raw/wales_ish_bbox.geojson")
  lsoa21_boundaries %>% 
    st_bbox() %>% 
    st_as_sfc() %>%
    st_write("data-raw/wales_ish_bbox.geojson")


  # Subset super-generalised
  unlink("output/lsoa21_boundaries.geojson")
  st_read("data-raw/lsoa21_boundaries_super_generalised.geojson") %>%
    filter(LSOA21CD %in% lsoa21_boundaries$LSOA21CD) %>%
    st_write("output/lsoa21_boundaries.geojson")

  return(lsoa21_boundaries)
}

