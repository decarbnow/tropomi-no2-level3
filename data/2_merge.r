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

for(i in 1:length(h5Files)){
    f = H5File$new(file.path(h5Path, h5Files[i]), mode="r+")
    
    tmp = f[["tropospheric_NO2_column_number_density"]][,,1]
    
    f$close_all()
    
    s = seq(-180, 180, l = nrow(tmp)+1)
    s = s[-c(nrow(tmp)+1)]
    length(s)
    rownames(tmp) = s
    
    s = seq(-90, 90, l = ncol(tmp)+1)
    s = s[-c(ncol(tmp)+1)]
    length(s)
    colnames(tmp) = s
    
    tmp = as.data.table(melt(tmp))
    setnames(tmp, c("X", "Y", "value"))
    tmp = tmp[!is.na(value)][value >= 0]
    no2List[[as.character(i)]] = tmp
    rm(tmp)
}

no2Data = rbindlist(no2List)

saveData(no2Data, file.path(folders$tmp, "data", "merged", paste0(month, "_", year, ".rData")))