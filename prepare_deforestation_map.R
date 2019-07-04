###########################################################################################################
#                                                                                                         #
#     Preparation of annual maps of forest loss where palm oil plantations stood in 2015                  #
#                                                                                                         #
#     Inputs: - georeferenced mills (from Heilmayr) (and their desa codes here but this is not needed)    #
#             ---> heilmayr_desa.Rdata                                                                    #
#                                                                                                         #
#             - oil palm plantations; already processed 2015 map from Austin here                         #
#             ---> new_oilpalm_2015_WGS1984.tif                                                           #
#                                                                                                         #
#             - Global Forest Change rasters downloaded on internet.                                      #
#                                                                                                         #
#     Output: 17 rasters of oil palm-imputable deforestation defo_1.tif to defo_17.tif                    #
#                                                                                                         #
###########################################################################################################


#THIS SCRIPT'S STRUCTURE
############################################################################################################
  # DEFINE AREA OF INTEREST (AOI)
  # DOWNLOAD APPROPRIATE HANSEN DEFORESTATION DATA
  # COMPUTE FOREST LOSS IMPUTABLE TO PALM OIL
  # PROJECT PALM-IMPUTABLE DEFORESTATION MAP
  # SPLIT THE SINGLE LAYER defo RASTER INTO ANNUAL LAYERS.
############################################################################################################

# WORKING DIRECTORY
setwd("C:/Users/guyv/ownCloud/opalval/build/input/deforestation")


# PACKAGES
neededPackages = c("plyr", "dplyr", "raster", "sf", "foreign", "sp", "lwgeom", "rnaturalearth", "data.table",
                   "rgdal",
                   "rlist", "velox", "parallel", "foreach", "iterators", "doParallel", "xlsx")
allPackages    = c(neededPackages %in% installed.packages()[ , "Package"]) 

# Install packages (if not already installed) 
if(!all(allPackages)) {
  missingIDX = which(allPackages == FALSE)
  needed     = neededPackages[missingIDX]
  lapply(needed, install.packages)
}

# Load all defined packages
lapply(neededPackages, library, character.only = TRUE)

# package tictoc
if (!require(devtools)) install.packages("devtools")
devtools::install_github("jabiru/tictoc")
library(tictoc)

install.packages("sf", source = TRUE)
if (!require(devtools)) install.packages("devtools")
devtools::install_github("r-spatial/lwgeom")
library(lwgeom)


#INSTALL GFC ANALYSIS
if (!require(devtools)) install.packages("devtools")
# Install the snow package used to speed spatial analyses
if (!require(snow)) install.packages("snow")
# Install Alex's gfcanalysis package
library(devtools)
install_github('azvoleff/gfcanalysis')
#and loading it
library(gfcanalysis)



###     IMPORTANT NOTE    ###
############################################################################################################
# GFC and palm oil data were extracted for a bounding box for buffers of 60km (as the codes below indicates). 
 # JUST CHECK AGAIN QUICKLY 
############################################################################################################


############################################################################################################
#   Rather than calling all relevant gfc tiles, mosaicing, and masking with catchment areas, we will first 
#   define an AOI corresponding to catchment areas (CAs) and load only Hansen's maps that cover them.     
#   BUT, the extract_gfc returns data for larger areas than the only AOI provided (we could see Malaysia).
#   We do it this way still. 
#
#   We don't use gfc_stats because we want to keep information at the pixel level and not at the aoi's in order 
#   to overlay it with plantations. 
############################################################################################################




##### DEFINE AREA OF INTEREST (AOI) #####
############################################################################################################

# load data.frame of heilmayr information plus desa code. 
load("C:/Users/guyv/ownCloud/opalval/build/input/heilmayr_desa.Rdata")  

#turn into an sf object. 
heilmayr_desa_sf <- st_as_sf(heilmayr_desa,	coords	=	c("longitude",	"latitude"), crs=4326)
class(heilmayr_desa_sf) # "sf" "data.frame"

# set CRS and project
st_crs(heilmayr_desa_sf) 
# EPSG 4326 - proj4string: "+proj=longlat +datum=WGS84 +no_defs" i.e. unprojected because of crs argument in st_as_sf above. 

#   Following http://www.geo.hunter.cuny.edu/~jochen/gtech201/lectures/lec6concepts/map%20coordinate%20systems/how%20to%20choose%20a%20projection.htm
#   the Cylindrical Equal Area projection seems appropriate for Indonesia extending east-west along equator. 
#   According to https://spatialreference.org/ref/sr-org/8287/ the Proj4 is 
#   +proj=cea +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs
#   which we center at Indonesian longitude with lat_ts = 0 and lon_0 = 115.0 
indonesian_crs <- "+proj=cea +lon_0=115.0 +lat_ts=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs"

heilmayr_desa_prj <- st_transform(heilmayr_desa_sf, crs = indonesian_crs) 
st_crs(heilmayr_desa_prj) # units are meters. 

#define big catchment areas to have a large AOI. 
heilmayr_ca60 <- st_buffer(heilmayr_desa_prj, dist = 60000)

aois <- st_geometry(heilmayr_ca60)


### 
# CODE TO extract_gfc USING to_UTM = FALSE ON A BOUNDING BOX OF CAs
AOI <- st_as_sfc(st_bbox(aois))

#give the aoi the same (unprojected) crs than the tiles (which extract_gfc would have done automatically anyway).
AOI_unprj <- st_transform(AOI, crs = 4326)

#convert the box to a SpatialPolygon object for compatibility with download_tiles methods. 
AOI_sp <- as(AOI_unprj, Class="Spatial")
rm(AOI_unprj, AOI, aois, heilmayr_ca60, heilmayr_desa_sf, heilmayr_desa)
###


### 
#CODE IF ONE WANTED TO RATHER extract_gfc USING to_UTM = TRUE ON A DISSOLVED POLYGON OF CAs
#   AOI <- st_union(aois)
#   #Note: let us not unproject so that the extract_gfc can directly reproject its output onto the UTM of AOI. 
#
#   AOI_sp <- as(AOI, "Spatial")
#   rm(aois, heilmayr_desa, heilmayr_desa_sf, heilmayr_desa_prj)
###

#########################################################################################################################



##### DOWNLOAD APPROPRIATE HANSEN DEFORESTATION DATA #####
#########################################################################################################################
  
#define where all tiles are going to be stored
data_folder <- getwd()

#Calculate tiles needed to cover the AOI
tiles <- calc_gfc_tiles(AOI_sp)

#download tiles, with all layers otherwise later extract does not work 
download_tiles(tiles, data_folder, images = c("treecover2000", "lossyear", "gain", "datamask"), dataset = "GFC-2017-v1.5")

# extract gfc data (can only extract all layers with default stack=change)
# to better understand extract_gfc see https://rdrr.io/cran/gfcanalysis/src/R/extract_gfc.R
extract_gfc(aoi_unprj_sp, data_folder, 
            stack = "change", 
            to_UTM = FALSE, 
            dataset = "GFC-2017-v1.5", 
            filename = "gfc_data.tif", 
            overwrite = TRUE )
###
# to extract and project in the same time (AOI_sp should be projected) but did not work, I don't know why. 
# extract_gfc(AOI_sp, data_folder, stack = "change", to_UTM = TRUE, 
# dataset = "GFC-2017-v1.5", filename = "gfc_data_prj.tif", overwrite = TRUE)
# defo_e <- raster("gfc_data_prj.tif")
# crs(defo_e)
###
########################################################################################################################



##### COMPUTE FOREST LOSS IMPUTABLE TO PALM OIL #####
########################################################################################################################

#extract lossyear layer.
gfc_data <- brick("gfc_data.tif")

#names(gfc_datats) #"gfc_data.1" "gfc_data.2" "gfc_data.3" "gfc_data.4"; .2 is lossyear (values going from 0 to 17). 
loss <- gfc_data[[2]]

#remove other layers
rm(gfc_data)

# read plantation map 2015 in. 
po <- raster("C:/Users/guyv/ownCloud/opalval/build/input/PALMOIL/new_oilpalm_2015_WGS1984.tif")

# po # resolution is 0.002277, 0.002277
# loss # resolution is 0.00025, 0.00025

# ALIGN PO ON LOSS: po is disaggregated and will match loss res, ext, and crs. Both are unprojected at this stage. 
    projectRaster(from = po, to = loss, 
                          method = "ngb", 
                          filename = "aligned_new_oilpalm_2015.tif", 
                          overwrite = TRUE )  

rm(po)

po_align <- raster("aligned_new_oilpalm_2015.tif")
    
  
# see only deforestation that happened where oil palm plantations stood in 2015 (po map is binary with 1 meaning plantation in 2015) 
     f <- function(loss, po_align) {loss*po_align}
     overlay(loss, po_align, 
             fun = f, 
             filename = "defo.tif", 
             overwrite = TRUE ) 

rm(loss, po_align, f)
#################################################################################################################################



##### PROJECT PALM-IMPUTABLE DEFORESTATION MAP #####
#################################################################################################################################

# This is necessary because we will need to make computations on this map within mills' catchment *areas*. 
# If one does not project this map, then catchment areas all have diffrent areas while being defined with a common buffer.

defo <- raster("defo.tif")
                                  
projectRaster(from = defo, 
              crs = indonesian_crs, 
              method = "ngb", 
              filename = "defo_prj.tif", 
              overwrite = TRUE )

rm(defo)
#################################################################################################################################



##### SPLIT THE SINGLE LAYER defo RASTER INTO ANNUAL LAYERS. #####
#################################################################################################################################

### read projected palm-imputable deforestation map
defo <- raster("defo_prj.tif")

                                  
### MASK ? is not useful because reclassifying NAs to 0s does not make the file lighter. 
# (and croping more is not possible.) 


years <- c(1:17)
for (t in 1:length(years)){ 
  annualrastername <- paste0("defo_", years[t],".tif")
  calc(defo, fun = function(x){if_else(x == years[t], true = 1, false = 0)}, 
       filename = annualrastername, 
       overwrite = TRUE ) 
}

rm(annualrastername, defo)
#################################################################################################################################


