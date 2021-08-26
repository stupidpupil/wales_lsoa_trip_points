decide_lsoas <- function(){
  lsoa11_boundaries <- st_read("data-raw/Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Super_Generalised_Clipped_(BSC)_EW_V3.geojson") %>%
    select(LSOA11CD, Shape__Area)

  area_of_interest <- st_read("data-raw/area_of_interest.geojson")

  lsoa11_boundaries <- lsoa11_boundaries[area_of_interest, , op=st_within]

  # Remove any islands
  touching_any_others <- lsoa11_boundaries %>% st_touches(lsoa11_boundaries, sparse=FALSE) %>% apply(1, any)
  lsoa11_boundaries <- lsoa11_boundaries[touching_any_others, ]

  #Require that we have all Welsh LSOAs
  stopifnot(lsoa11_boundaries %>% filter(LSOA11CD %>% str_detect("^W")) %>% nrow() == 1909)

  unlink("output/lsoa11_boundaries.geojson")
  lsoa11_boundaries %>% st_write("output/lsoa11_boundaries.geojson")

  unlink("data-raw/wales_ish_bbox.geojson")
  lsoa11_boundaries %>% 
    st_bbox() %>% 
    st_as_sfc() %>%
    st_write("data-raw/wales_ish_bbox.geojson")

  return(lsoa11_boundaries)
}