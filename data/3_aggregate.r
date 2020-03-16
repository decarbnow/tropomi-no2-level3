# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./base/init.r", chdir=TRUE)
# ----------------------------------------------
year = "2020"
month = "03"

no2Data = loadData(file.path(folders$tmp, "data", "merged", paste0(month, "_", year, ".rData")))
mData = no2Data[, .(mValue = median(value)), by = c("X", "Y")]

saveData(mData, file.path(folders$tmp, "data", "aggregated", paste0(month, "_", year, ".rData")))
