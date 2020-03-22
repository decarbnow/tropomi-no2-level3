# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./base/init.r", chdir=TRUE)
loadPackages(c("raster", 
               "leaflet", 
               "rgdal", 
               "smoothr", 
               "units", 
               "lwgeom", 
               "rgeos", 
               "sf"))

# ----------------------------------------------

# ----------------------------------------------
# SETUP
# ----------------------------------------------
#path = "/home/archie/WIFO_cumulus/sentinel"
year = "2020"
month = "02"
qnt = 0.95
quantile_selection = c(0, 0.4, 0.6, 0.8, 0.85, 0.92, 0.95, 0.97, 0.99, 0.995)
# ----------------------------------------------

path = file.path(file.path(folders$tmp, "data", "aggregated"))
files = list.files(path)

meanData = loadData(file.path(path, paste0(month, "_", year, ".rData")))

meanData = meanData[mValue >= quantile(meanData$mValue, qnt)]
meanData[, q := rank(mValue)/nrow(meanData)]

l = length(quantile_selection) 

for (i in 1:l) {
  meanData[q >= quantile_selection[i], g := i]
}

meanData = meanData[, .(X, Y, g)]

meanRaster = rasterFromXYZ(meanData)  #Convert first two columns as lon-lat and third as value                
crs(meanRaster) = sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")



# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")

leaflet_map = leaflet_map %>%
  addRasterImage(meanRaster, colors = "Spectral", opacity = 0.8)

leaflet_map
# ----------------------------------------------