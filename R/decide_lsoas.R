decide_lsoas <- function(){
  lsoa11_boundaries <- st_read("data-raw/lsoa11_boundaries.geojson") %>%
    select(LSOA11CD, Shape__Area)

  area_of_interest <- st_read("data-raw/area_of_interest.geojson")

  lsoa11_boundaries <- lsoa11_boundaries[area_of_interest, , op=st_intersects]

  # Remove any islands
  touching_any_others <- lsoa11_boundaries %>% st_touches(lsoa11_boundaries, sparse=FALSE) %>% apply(1, any)
  lsoa11_boundaries <- lsoa11_boundaries[touching_any_others, ]

  #Require that we have all Welsh LSOAs
  stopifnot(lsoa11_boundaries %>% filter(LSOA11CD %>% str_detect("^W")) %>% nrow() == 1909)

  unlink("data-raw/lsoa11_boundaries_subset.geojson")
  lsoa11_boundaries %>% st_write("data-raw/lsoa11_boundaries_subset.geojson")


  unlink("data-raw/wales_ish_bbox.geojson")
  lsoa11_boundaries %>% 
    st_bbox() %>% 
    st_as_sfc() %>%
    st_write("data-raw/wales_ish_bbox.geojson")


  # Subset super-generalised
  unlink("output/lsoa11_boundaries.geojson")
  st_read("data-raw/lsoa11_boundaries_super_generalised.geojson") %>%
    filter(LSOA11CD %in% lsoa11_boundaries$LSOA11CD) %>%
    st_write("output/lsoa11_boundaries.geojson")

  return(lsoa11_boundaries)
}