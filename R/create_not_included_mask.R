create_not_included_mask <- function(){

  unlink("output/external_mask.geojson")

  sf::read_sf("data-raw/lsoa11_boundaries_super_generalised.geojson") |>
    sf::st_bbox() |> sf::st_as_sfc() |>
    sf::st_transform(crs = "EPSG:27700") |>
    sf::st_buffer(100000) |>
    sf::st_transform(crs = "EPSG:4326") |>
    sf::st_bbox() |> sf::st_as_sfc() |>
    sf::st_difference(sf::read_sf("output/lsoa11_boundaries.geojson") |> sf::st_union()) |>
    sf::write_sf("output/external_mask.geojson")


}