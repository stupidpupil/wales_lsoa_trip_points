# Code to generate LSOA11 Trip-points for Wales

This repository contains code to generate geographical trip-points for each 2011 Lower Layer Super Output Area (LSOA11) in Wales, and some LSOA11s in bordering areas in England, for transport-related analysis.

You can find [the latest release of these trip-points here](https://github.com/stupidpupil/wales_lsoa_trip_points/tree/points-releases).

It attempts to address the problem that for some LSOAs, particularly rural ones, the [population-weighted centroid](https://geoportal.statistics.gov.uk/documents/b20460edf2f3459fa7d2771eacab51fc/explore) might be in the middle of nowhere - far away from any actual place, public transport stop or road. Trip planners may not be able to find routes to and from these centroids.

## Method

These “trip-points” are generated in a two-step process:
1. For roughly the third of the included LSOAs with the greatest areas, I find the village, town, bus stop, train station or pub nearest to the population-weighted centroid.

2.  For each LSOA, I find the nearest motor-vehicle accessible road to a) the place found in the first step for the 850 or so biggest LSOAs or b) the population-weighted centroid for the 1750 or so remaining LSOAs.

The first step attempts to find points where it might actually be possible to start a public transport journey, while the second step all but guarantees that it will be possible to start a car-based journey.

## Advantages and disadvantages of LSOA-level analysis

- Many existing analytical products are only available at LSOA-level or higher, for example [Car and van availability from the 2011 Census](https://www.nomisweb.co.uk/census/2011/qs416ew) and different countries' [Indices of Deprivation](https://github.com/mysociety/composite_uk_imd).

- LSOAs are a relatively manageable number of data points (1909 LSOAs in Wales) resulting in relatively manageable travel-time matrices (around 3.6 million cells in Wales, around 12MiB in a CSV), in contrast to Output Areas (ten thousand OAs resulting in 100 million cells in a travel time matrix).

- Rural LSOAs can have very large geographical areas containing multiple scattered settlements; a single trip-point for such an area may be extremely unrepresentative, and accessibility - particularly for public transport - determined based on such a point may be quite misleading.

## Known Issues

- Some routers (including OpenTripPlanner) may have issues navigating from roads that don't have access restrictions themselves but are accessible only via roads that do. 

- Not all bus stops and railway stations are mapped in OpenStreetMap. In particular, many of the former are missing from rural parts of Wales. This may lead to suboptimal place selection in the first step. (An alternative might be to use the NaPTAN database.)

## How-to

```r
devtools::load_all()
decide_lsoas()
download_osm()
extract_osm()
decide_place_points()
decide_nearest_road_points()
```
