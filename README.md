# LSOA11 Trip-points for Wales

This repository contains code to generate geographical trip-points for each 2011 Lower Layer Super Output Area (LSOA11) in Wales for transport-related analysis.

It attempts to address the problem that for some LSOAs, particularly rural ones, the [population-weighted centroid](https://geoportal.statistics.gov.uk/documents/b20460edf2f3459fa7d2771eacab51fc/explore) might be in the middle of nowhere - far away from any actual place, public transport stop or road. Trip planners may not be able to find routes to and from these centroids.

These “trip-points” are generated in the following way:
- 25 LSOAs have a trip point manually defined,
- 852 LSOAs with an area bigger than the Welsh median and containing at least one “Community” or “Locality” have their trip point set to the location of the Community or Locality nearest to the population-weighted centroid, and
- the 1032 remaining LSOAs just use the population-weighted centroid.

## Communities and Localities

These are places described in the [Index of Place Names in Great Britain](https://geoportal.statistics.gov.uk/datasets/e8e725daf8944af6a336a9d183114697/about). “Localities” are “villages, hamlets and localities without legally defined boundaries” and “Communities” are the [smallest areas of civil administration in Wales](https://webarchive.nationalarchives.gov.uk/20160112001128/http://www.ons.gov.uk/ons/guide-method/geography/beginner-s-guide/administrative/england/parishes-and-communities/index.html).

## Distance of Trip-points from Centroids

The plot below shows the distance of the trip-point from the population-weighted centroids for the LSOAs where the two differ.

![](distance_plot.png)

## License

The code and trip-points are licensed under the [MIT licence](https://opensource.org/licenses/MIT).

The trip-points are derived from several datasets provided by the Office for National Statistics licensed under the Open Government Licence v.3.0 and containing OS Data © Crown copyright and database right 2021, reproduced in the *data-raw* directory.

These datasets include:
- [Index of Place Names in Great Britain](https://geoportal.statistics.gov.uk/datasets/e8e725daf8944af6a336a9d183114697/about)
- [LSOA11 Population-Weighted Centroids](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-population-weighted-centroids/about)
- [LSOA11 Boundaries](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-boundaries-super-generalised-clipped-bsc-ew-v3/about)
