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
year = "2019"
month = "10"
qnt = 0.95
quantile_selection = c(0, 0.4, 0.6, 0.8, 0.85, 0.92, 0.95, 0.97, 0.99, 0.995)
#quantile_selection = c(0, 0.4, 0.8, 0.95, 0.97)
crumps = c(10000, 5000, 4000, 3000, 2000, 1800, 1600, 200, 200, 200)
#crumps = c(10000, 5000, 1800, 1000, 200)
f_holes = c(3001, 3000, 2000, 1000, 1000, 1000, 1000, 1000, NA, NA)
#f_holes = c(3001, 3000, 2000, 1000, NA)

opast = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)
border_smooth = 3
simplify_tol = 0.02
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

rasters = list()

for (i in 1:l) {
  print(paste0(i, "/", l))
  t = meanData[g >= i, .(X, Y, trans = opast[i])]
  tt = rasterFromXYZ(t)  #Convert first two columns as lon-lat and third as value                
  crs(tt) = sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  print("Drop Crumps")
  tt = drop_crumbs(rasterToPolygons(tt, dissolve=TRUE), 
                   set_units(crumps[i], km^2))
  rasters[i] = tt
} 

polys = list()
for (i in 1:l) {
  print(paste0(i, "/", l))
  
  tt = rasters[[i]]
  
  print("Fill Holes")
  if(!is.na(f_holes[i]))
    tt = fill_holes(tt, set_units(f_holes[i], km^2))
  print("Smooth")
  tt = smooth(tt, method = "ksmooth", smoothness=border_smooth)
  print("Simplify")
  ttd = data.frame(tt)
  #tt = gSimplify(tt, tol = simplify_tol, topologyPreserve=TRUE)
  tt = SpatialPolygonsDataFrame(tt, ttd)
  polys[i] = tt
} 

# ----------------------------------------------

# ----------------------------------------------
# RBIND, SAVE
# ----------------------------------------------
final_poly = do.call( rbind, polys )

writeOGR(final_poly, file.path(folders$tmp, paste0("World_", year, "_", month, ".geojson")), layer="dfr_pg", driver="GeoJSON", overwrite_layer = TRUE)
#stop("EOF. Run code below to plot data on leaflet map.")
# ----------------------------------------------

# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
poly_colors = c("brown", "purple", "red", "green", "blue", "yellow", "black", "gray", "white", "orange")

leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")

for(i in 1:length(rasters)){
    leaflet_map = leaflet_map %>%
      #addRasterImage(rasters[[i]], colors = poly_colors[i], opacity = 0.8)
      addPolygons(data = polys[[i]], color = poly_colors[i])
}

leaflet_map
# ----------------------------------------------



