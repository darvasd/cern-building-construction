# cern-building-construction
Animation to show the construction of CERN's buildings

See the [R script](meyrin/generate-images.R) for the implementation.

The steps are essentially the following:
1. Fetch data from OpenStreetMap (using the `osmar` package)
1. Collect the buildings within the bounding box of the site
1. Clean their names and look up their construction year from the [included file](meyrin/cern_building_years.csv), created using various publicly available sources.
    * Some building names had to be adjusted to their OSM names
1. For each year from 1954 to 2018, plot the buildings built by that year
    * Note that as the output is a filtered version of the OSM data, only the buildings still standing are shown for each year.
1. Use [ImageMagick](https://www.imagemagick.org) to convert the individual PNGs into an animated GIF.

## Result

### CERN's Meyrin site
![Construction of the Meyrin site](meyrin/result/animation.gif)