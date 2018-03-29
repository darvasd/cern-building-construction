# R script to generate a figure for each year with the CERN buildings that were
# already built by that year.
# Rather quick and dirty script.
#
# Lots of ideas from here:
# https://journal.r-project.org/archive/2013-1/eugster-schlesinger.pdf

filename_prefix <- "cern_meyrin"
text_color <- "#007878"
bg_color <- "white"   #"#e7f4f4"
font <- "Open Sans"
imagemagick_convert_location <- "convert" # Put the full path of ImageMagick's convert utility here if it is not on the path.

# Loading and initializing osmar package
library("osmar")
	# If you don't have it, install with `install.packages("osmar")`

# Loading fonts. If you want to skip this, default will be used.
library(extrafont)
# Before first execution you need to install extrafont package (`install.packages("extrafont")`) 
# and then execute `font_import()`.
# The `fonts()` will tell you the available fonts.
loadfonts(device = "win") # To register fonts for PNG device as well.


src <- osmsource_api()

# Get polygon of the CERN site (can be used to filter the data)
meyrin_site <- get_osm(way(174126176), source = src, full = TRUE)
	# Meyrin ID: 174126176
	# Prévessin ID: 23722021

# Calculate the bounding box
min_lon <- min(meyrin_site$nodes$attrs$lon)
max_lon <- max(meyrin_site$nodes$attrs$lon)
min_lat <- min(meyrin_site$nodes$attrs$lat)
max_lat <- max(meyrin_site$nodes$attrs$lat)
meyrin_box <- corner_bbox(min_lon, min_lat, max_lon, max_lat)

# Fetch all data within the bounding box
# (It takes some time...)
meyrin_contents <- get_osm(meyrin_box, source=src)

# Filter the nodes which represent building within the bounding box
building_ids <- find(meyrin_contents, way(tags(k=="building")))
building_ids <- find_down(meyrin_contents, way(building_ids))
buildings <- subset(meyrin_contents, ids = building_ids)

# Convert building nodes to polygons
building_poly <- as_sp(buildings, "polygons")

# Get the OSM names of the buildings
get_building_name <- function(way_id) {
	x <- subset(meyrin_contents, way_ids = way_id)
	tags <- x$ways$tags
	row.names(tags) <- tags$k
	name <- tags['name','v']
	name <- as.character(name)
	return(name)
}
building_names <- lapply(building_poly$id, get_building_name)
building_poly$name <- building_names

# Load building construction years
building_years <- read.csv("cern_building_years.csv", sep=";")
row.names(building_years) <- as.character(building_years$Building_number)

# Determine the construction year for each building
get_construction_year <- function(building_number) {
	sanitized_bdg_number <- gsub(".*\\b(\\d+)\\b.*", "\\1", building_number)
	y <- building_years[sanitized_bdg_number,'Year']
	if (is.na(y) || y=='-') {
		cat("Construction year is unknown for", sanitized_bdg_number, "/", building_number, "\n")
		return(0)
	}
	return(as.integer(as.character(y)))
}
year <- lapply(building_poly$name, get_construction_year)
building_poly$year <- year

# Plotting buildings build in each year
site_meyrin <- as_sp(meyrin_site, "polygons")
bdg_with_yearinfo <- building_poly[which(building_poly@data$year > 0),]

plot_year <- function(y){
	bdg_already_existing <- building_poly[which(building_poly@data$year > 0 & building_poly@data$year < y),]
	bdg_built_thisyear <- building_poly[which(building_poly@data$year == y),]
	
	# Invisible background, to keep the size content
	plot(bdg_with_yearinfo, col="black", border="white")
	
	# Light background to show the current area of the site
	plot(site_meyrin, col="#f4f4f4", border="gray")
	
	# Buildings already existing before year 'y' in grey
	plot(bdg_already_existing, add=TRUE, col="gray", lwd=1.5)
	
	# Buildings built in year 'y' in red
	plot(bdg_built_thisyear, add=TRUE, col="red", lwd=2)
	
	xleft <- par("usr")[1]
	xright <- par("usr")[2]
	ybottom <- par("usr")[3]
	ytop <- par("usr")[4]
	
	# Plot year
	text(xright, ytop + (ybottom-ytop)*0.02, y, adj = c(1,1), col=text_color, cex=10, family=font)
	# ideas from http://sphaerula.com/legacy/R/placingTextInPlots.html
	
	# Plot number of buildings
	# number_of_buildings <- length(bdg_already_existing) + length(bdg_built_thisyear)
	# text(xright, ybottom, sprintf("%d", number_of_buildings), adj = c(1,0), col=text_color, cex=2) 
	
	text(xleft, ybottom - (ybottom-ytop)*0.05, "Map data: (c) OpenStreetMap\n@DarvasDaniel,  2018", adj = c(0,0), col=text_color, cex=2, family=font)
}

# Create PNGs for each year
for(y in 1954:2018){
	png(width=1600, height=1200, filename=sprintf("%s_%s.png", filename_prefix, y), antialias="gray", type="cairo", bg="white")
	plot_year(y)
	dev.off()
	cat("Year", y, "done.\n")
}

# Create animated gif using ImageMagick
animgif_command <- sprintf('%s -delay 25x100 %s_*.png -delay 100x100 %s_%d.png -loop 0 result/animation.gif', imagemagick_convert_location, filename_prefix, filename_prefix, y)
  # Note the longer delay for the last year's frame
system(animgif_command)