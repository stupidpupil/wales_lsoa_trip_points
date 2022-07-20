download_lsoa_data <- function() {

  old_options <- options(timeout=6000)
  on.exit(options(old_options))

  boundaries_url <- "https://opendata.arcgis.com/api/v3/datasets/1f23484eafea45f98485ef816e4fee2d_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  boundaries_path <- "data-raw/lsoa11_boundaries.geojson"
  download.file(boundaries_url, boundaries_path)

  boundaries_super_gen_url <- "https://opendata.arcgis.com/api/v3/datasets/e9d10c36ebed4ff3865c4389c2c98827_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  boundaries_super_gen_path <- "data-raw/lsoa11_boundaries_super_generalised.geojson"
  download.file(boundaries_super_gen_url, boundaries_super_gen_path)

  centroids_url <- "https://opendata.arcgis.com/api/v3/datasets/b7c49538f0464f748dd7137247bbc41c_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  centroids_path <- "data-raw/lsoa11_centroids.geojson"
  download.file(centroids_url, centroids_path)
}

