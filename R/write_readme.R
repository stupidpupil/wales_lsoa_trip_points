write_trip_points_readme <- function(){
  rmarkdown::render("data-raw/README.Rmd", knit_root_dir="..", output_dir="output", output_format="all")
}

