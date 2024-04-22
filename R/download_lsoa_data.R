download_lsoa_data <- function() {

  old_options <- options(timeout=6000)
  on.exit(options(old_options))

  boundaries_url <- "https://opendata.arcgis.com/api/v3/datasets/761ecd09b4124843b95511a242e2b1a1_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  boundaries_path <- "data-raw/lsoa21_boundaries.geojson"
  download.file(boundaries_url, boundaries_path)

  boundaries_super_gen_url <- "https://opendata.arcgis.com/api/v3/datasets/f3b0086377fa4b418197637e8e03c7b5_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  boundaries_super_gen_path <- "data-raw/lsoa21_boundaries_super_generalised.geojson"
  download.file(boundaries_super_gen_url, boundaries_super_gen_path)

  centroids_url <- "https://opendata.arcgis.com/api/v3/datasets/79fa1c80981b4e4eb218bbce1afc304b_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  centroids_path <- "data-raw/lsoa21_centroids.geojson"
  download.file(centroids_url, centroids_path)
}

