# LSOA11 Trip-points for Wales

This repository contains code to generate geographical trip-points for each 2011 Lower Layer Super Output Area (LSOA11) in Wales for transport-related analysis.

It attempts to address the problem that for some LSOAs, particularly rural ones, the [population-weighted centroid](https://geoportal.statistics.gov.uk/documents/b20460edf2f3459fa7d2771eacab51fc/explore) might be in the middle of nowhere - far away from any actual place, public transport stop or road. Trip planners may not be able to find routes to and from these centroids.

## Method

These “trip-points” are generated in a two-step process:
1. For roughly the third of Welsh LSOAs with the greatest areas, I find the village, town, bus stop, train station or pub nearest to the population-weighted centroid.

2.  For each LSOA, I find the nearest motor-vehicle accessible road to a) the place found in the first step for the 600 or so biggest LSOAs or b) the population-weighted centroid for the 1,300 or so remaining LSOAs.

The first step attempts to find points where it might actually be possible to start a public transport journey, while the second step all but guarantees that it will be possible to start a car-based journey.

## Distance of Trip-points from Centroids

The plot below shows the distance of the trip-point from the population-weighted centroids for each LSOA.

![](distance_plot.png)

## Advantages and disadvantages of LSOA-level analysis

- Many existing analytical products are only available at LSOA-level or higher, for example [Car and van availability from the 2011 Census](https://www.nomisweb.co.uk/census/2011/qs416ew) and different countries' [Indices of Deprivation](https://github.com/mysociety/composite_uk_imd).

- LSOAs are a relatively manageable number of data points (1909 in Wales) resulting in relatively manageable travel-time matrices (around 3.6 million cells in Wales), in contrast to Output Areas (ten thousand OAs resulting in 100 million cells in a travel time matrix).

- Rural LSOAs can have very large geographical areas containing multiple scattered settlements; a single trip-point for such an area may be extremely unrepresentative, and accessibility - particularly for public transport - determined based on such a point may be quite misleading.

## License

The trip-points are made available under the [ODbL v1.0](https://opendatacommons.org/licenses/odbl/1-0/) by Adam Watkins.

The trip-points are derived from several datasets provided by the Office for National Statistics licensed under the Open Government Licence v.3.0 and contain OS Data © Crown copyright and database right 2021.

These datasets include:
- [LSOA11 Population-Weighted Centroids](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-population-weighted-centroids/about)
- [LSOA11 Boundaries](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-boundaries-super-generalised-clipped-bsc-ew-v3/about)

They are also derived from information about places and roads obtained from [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), via [Geofabrik.de](https://download.geofabrik.de/europe/great-britain.html), under the [ODbL v1.0](https://opendatacommons.org/licenses/odbl/1-0/).
