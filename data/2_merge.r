# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./base/init.r", chdir=TRUE)
loadPackages(c("hdf5r", "raster"))
# ----------------------------------------------
validity = 50
pixelSize = 0.1
year = "2020"
month = "03"
h5Path = file.path(folders$tmp, "data", "h5", pixelSize, validity)
h5Files = list.files(h5Path, full.names = FALSE)

h5Files = h5Files[which(paste0(year, month) == substr(h5Files, 21, 26))]

no2List = list()
s_rows = seq(-180+pixelSize/2, 180-pixelSize/2, l = 360/pixelSize)
s_cols = seq(-90+pixelSize/2, 90-pixelSize/2, l = 180/pixelSize)

for(i in 1:length(h5Files)){
    print(paste(i, "of", length(h5Files)))
    f = H5File$new(file.path(h5Path, h5Files[i]), mode="r+")
    
    tmp = f[["tropospheric_NO2_column_number_density"]][,,1]
    
    f$close_all()

    rownames(tmp) = s_rows

    colnames(tmp) = s_cols
    
    tmp = as.data.table(melt(tmp))
    setnames(tmp, c("X", "Y", "value"))
    tmp = tmp[!is.na(value)][value >= 0]
    no2List[[as.character(i)]] = tmp
    rm(tmp)
    gc()
}

no2Data = rbindlist(no2List)

saveData(no2Data, file.path(folders$tmp, "data", "merged", paste0(month, "_", year, ".rData")))
