# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./base/init.r", chdir=TRUE)
# ----------------------------------------------

# ----------------------------------------------
# CONFIG
# ----------------------------------------------
validities = c(50, 75)
pixelSizes = c(0.1)

t1 = "2019-01-12T00:00:00.000Z"
t2 = "2019-04-01T00:00:00.000Z"
#t2 = "NOW"
removeFile = TRUE
# ----------------------------------------------

# ----------------------------------------------
# PREPARATION / LOAD FILE LISTS
# ----------------------------------------------
rawPath = file.path(folders$tmp, "data", "tropomi")
dir.create(rawPath, showWarnings = FALSE, recursive=TRUE)
dir.create(h5Path, showWarnings = FALSE, recursive=TRUE)
listPath = file.path(rawPath, "list.txt")

listUrl = paste0("https://s5phub.copernicus.eu/dhus/api/stub/products?filter=(%20beginPosition:[",
                 t1, "%20TO%20", t2,
                 "]%20AND%20endPosition:[", 
                 t1, "%20TO%20", t2, 
                 "]%20)%20AND%20(%20%20(platformname:Sentinel-5%20AND%20producttype:L2__NO2___%20AND%20processinglevel:L2%20AND%20processingmode:Offline))&offset=0&limit=10000&sortedby=ingestiondate&order=asc")

download.file(listUrl,
              destfile = listPath,
              quiet = TRUE,
              method="wget",
              extra=paste0("--user=", authUser, " --password=", authPassword))

downloadList = rjson::fromJSON(file=file.path(rawPath, "list.txt"))

getList = NULL
for(i in 1:length(downloadList[["products"]])){
    tmp = data.table(uuid = downloadList[["products"]][[i]][["uuid"]],
                     identifier = downloadList[["products"]][[i]][["identifier"]])
    getList = rbind(getList, tmp)
}
# ----------------------------------------------

# ----------------------------------------------
# DOWNLOAD
# ----------------------------------------------
u = "https://s5phub.copernicus.eu/dhus/odata/v1/Products"
for(i in 1:nrow(getList)){
    uuid = getList[[i,1]]
    identifier = getList[[i,2]]
    print(identifier)

    rawFilePath = file.path(rawPath, identifier)
    
    h5Paths = file.path(folders$tmp, "data", "h5", 
                        apply(expand.grid(pixelSizes, validities), 1, 
                              paste, collapse = "/"))
    h5Paths
    h5FilePaths = file.path(h5Paths, paste0(identifier, ".h5"))
    
    if(all(file.exists(h5FilePaths), TRUE)) {
        next()
    }
    
    if(!file.exists(rawFilePath)){
        tropomiUrl = paste0(u, "('", uuid, "')/$value")
        
        download.file(tropomiUrl,
                      destfile = rawFilePath,
                      quiet = TRUE,
                      method="wget",
                      extra=paste0("--user=", authUser, " --password=", authPassword))
        
        print("Downloading completed. Next.")
    }
    
    for(pixelSize in pixelSizes){
        pixelNlat = 180*1/pixelSize+1
        pixelNlon = 360*1/pixelSize+1
        
        for(validity in validities){
            savePath = file.path(folders$tmp, "data", "h5", pixelSize, validity)
            saveFilePath = file.path(savePath, paste0(identifier, ".h5"))
            
            if(file.exists(saveFilePath)){
                next()
            }
            print(paste("Creating raster file for validity", validity, "and pixel size", pixelSize))
            command = paste0("/home/archie/harp/bin/harpconvert --format hdf5 --hdf5-compression 9 -a ",
                             "'tropospheric_NO2_column_number_density_validity>", 
                             validity, ";derive(datetime_stop {time}); ",
                             "bin_spatial(", 
                             pixelNlat, ",-90,", pixelSize, ",", pixelNlon, ",-180,", pixelSize, 
                             "); keep(tropospheric_NO2_column_number_density)' ",
                             rawFilePath, 
                             " ", 
                             saveFilePath)
            
            print("Converting with harp")
            
            system(command, intern = FALSE,
                   ignore.stdout = FALSE, ignore.stderr = FALSE,
                   wait = TRUE, input = NULL, 
                   timeout = 0)
        }
        
    }
    

    if(removeFile)
        file.remove(rawFilePath)
    
    gc()
}
# ----------------------------------------------