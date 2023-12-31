#' Get base data required from bc data catalogue
#'
#' @param in_aoi an sf object containing a polygon with the area of interest to extract to
#' @param out_path file folder location where raw data will be saved (as gpkg)
#' @param overwrite TRUE or FALSE if you wish to overwrite existing data
#'
#' @return a series of geopackages with used as base data from moose strtatification
#' @importFrom magrittr "%>%"
#' @export
#'
#' @examples
#' \dontrun{
#' get_basedata(in_aoi, out_path)
#' }

get_basedata <- function(in_aoi, out_path, overwrite = FALSE){

  ## by block
 #in_aoi = tmp_aoi
 #out_path = temp_out_dir
 #overwrite = FALSE

  if(missing(in_aoi)) stop("'aoi' is missing with no default")

  # Second, detect object type and convert where necessary
  if(!inherits(in_aoi, c("sf", "sfc")))
    stop("'aoi' is not an sf or sfc object.")

  # Detect the CRS of the sf object
  if(is.na(sf::st_crs(in_aoi)))
    stop("CRS is not assigned. Use sf::st_crs() to assign a valid CRS to in_aoi")

  if(sf::st_is_longlat(in_aoi)) {
    cat("Input CRS is Lat/Long format. Transforming to EPSG 3005 (BC Albers) for processing\n")
    epsg <- 3005L
    in_crs <- sf::st_crs(in_aoi)
    in_aoi <- sf::st_transform(in_aoi, epsg) %>% sf::st_set_agr("constant")
  }

  epsg <- st_crs(in_aoi)

  # 1: download vri

  get_VRI <- function(in_aoi, out_path) {

    vri_exists <- file.exists(file.path(out_path, "vri.gpkg"))

    if(overwrite == FALSE & vri_exists == TRUE) {

    message("\rvri already exists, select overwrite = TRUE to force download of VRI layers")

    } else {

    message("\rDownloading VRI layers")

    vri <- bcdata::bcdc_query_geodata("2ebb35d8-c82f-4a17-9c96-612ac3532d55") %>%
      bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
      bcdata::select(c("SPECIES_CD_1", "SPECIES_CD_2","SPECIES_CD_3","SPECIES_CD_4","SPECIES_CD_5","SPECIES_CD_6",
                       "BCLCS_LEVEL_3")) %>% # Treed sites
      bcdata::collect() %>%
      {if(nrow(.) > 0) sf::st_intersection(., in_aoi) else .}

      sf::st_write(vri, file.path(out_path, "vri.gpkg"), append = FALSE)
    }
    return(TRUE)

    }


  # 2. download water bodies

  get_water <- function(in_aoi, out_path) {

    water_exists <- file.exists(file.path(out_path, "lakes.gpkg"))

    if(overwrite == FALSE & water_exists == TRUE) {

      message("\rwater already exists, skipping download, select overwrite = TRUE to force download of water layers")

    } else {


      message("\rDownloading lake, streams and wetland layers")

      ## LAKES ##

      # 1 Square Kilometer = 100.00 Hectare

      # Uses date filter which filters lakes
      lakes <- bcdata::bcdc_query_geodata("cb1e3aba-d3fe-4de1-a2d4-b8b6650fb1f6") %>%
        bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
        bcdata::select(id, WATERBODY_TYPE, AREA_HA) %>%
        bcdata::collect()

      if(length(st_is_empty(lakes)) > 0 ){
      lakes <- lakes %>% dplyr::select("id", "WATERBODY_TYPE", "AREA_HA")
      sf::st_write(lakes, file.path(out_path, "lakes.gpkg"), append = FALSE)
      }

  # download wetlands

      wetlands <- bcdata::bcdc_query_geodata("93b413d8-1840-4770-9629-641d74bd1cc6") %>%
        bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
        bcdata::select(id, WATERBODY_TYPE, AREA_HA) %>%
        bcdata::collect()

      wetlands <- wetlands %>% dplyr::filter(AREA_HA < 100) %>%
        dplyr::select(id, WATERBODY_TYPE, AREA_HA)%>%
        sf::st_union()

      if(length(st_is_empty(wetlands) > 0)){
        sf::st_write(wetlands, file.path(out_path, "wetlands.gpkg"), append = FALSE)
      }

    }

      return(TRUE)
    }

  # 3. download stream index

  get_streams <- function(in_aoi, out_path) {

    streams_exists <- file.exists(file.path(out_path, "streams.gpkg"))

    if(overwrite == FALSE & streams_exists == TRUE) {

      message("\r streams already exists, skipping download, select overwrite = TRUE to force download of water layers")

    } else {

    message("\rDownloading streams")

  #streamd <- bcdc_describe_feature("92344413-8035-4c08-b996-65a9b3f62fca")
  streams <- bcdata::bcdc_query_geodata("92344413-8035-4c08-b996-65a9b3f62fca") %>%
    bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
    bcdata::select(c(id, STREAM_ORDER)) %>%
    bcdata::collect()

  if(length(st_is_empty(streams)) > 0 ){
    streams <- streams %>% dplyr::select(c("id", "STREAM_ORDER"))%>%
      sf::st_zm()

   sf::st_write(streams, file.path(out_path, "streams.gpkg"), append = FALSE)
    }
  }

    return(TRUE)
      }


  # 4. download fire history

  get_fires <- function(in_aoi, out_path) {

    fire_exists <- file.exists(file.path(out_path, "fire.gpkg"))

    if(overwrite == FALSE & fire_exists == TRUE) {

      message("\rfirealready exists, skipping download, select overwrite = TRUE to force download of water layers")

    } else {

      message("\rDownloading fire disturbance")

      # check the sticky columns
      #ff<- bcdc_describe_feature("cdfc2d7b-c046-4bf0-90ac-4897232619e1")

      fire_records <- c("cdfc2d7b-c046-4bf0-90ac-4897232619e1",
                        "22c7cb44-1463-48f7-8e47-88857f207702")

      fires_all <- NA ## placeholder

      for (i in 1:length(fire_records)) {
        #i = 2
        fires <- bcdata::bcdc_query_geodata(fire_records[i]) %>%
          bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
          bcdata::select(id, FIRE_YEAR)%>%
          collect() %>%
          {if(nrow(.) > 0) sf::st_intersection(., in_aoi) else .}

        if(nrow(fires) > 0) {
          ## bind results of loops
          if (i == 1) {
            fires_all <- fires } else { ## i > 1
              if(all(is.na(fires_all))) {fires_all <- fires } else {fires_all <- rbind(fires_all, fires)}
            }
        } #else {print("No fires in layer queried") }

        # rm(fires)
      } ## end loop


      if (all(is.na(fires_all)) || nrow(fires_all) == 0) {
        print("No recent fire disturbance in area of interest") } else {
          sf::st_write(fires_all, file.path(out_path, "fire.gpkg"), append = FALSE)
        }

      }
      return(TRUE)
    }

  # 5. download fire intensity

  get_fire_intensity <- function(in_aoi, out_path) {

    fire_int_exists <- file.exists(file.path(out_path, "fire_int.gpkg"))

    if(overwrite == FALSE & fire_int_exists == TRUE) {

      message("\r fire intensity already exists, skipping download, select overwrite = TRUE to force download of water layers")

    } else {

      message("\rDownloading fire intensity")
      # check the sticky columns
      #ff<- bcdc_describe_feature("cdfc2d7b-c046-4bf0-90ac-4897232619e1")

      fire_int_records <- c("c58a54e5-76b7-4921-94a7-b5998484e697",
                        "04c5ad28-d8eb-4c49-90c5-48b9b98fdfe9")

      fires_int_all <- NA ## placeholder

      for (i in 1:length(fire_int_records)) {
        #i = 1
        fires_int <- bcdata::bcdc_query_geodata(fire_int_records[i]) %>%
          bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
          bcdata::select(id, FIRE_YEAR, BURN_SEVERITY_RATING)%>%
          bcdata::filter(BURN_SEVERITY_RATING %in% c("High", "Medium")) %>%
          collect() %>%
          {if(nrow(.) > 0) sf::st_intersection(., in_aoi) else .}

        if(nrow(fires_int) > 0) {
          ## bind results of loops
          if (i == 1) {
            fires_int_all <- fires_int } else { ## i > 1
              if(all(is.na(fires_int_all))) {fires_int_all <- fires_int } else {fires_int_all <- rbind(fires_int_all, fires_int)}
            }
        }

      } ## end loop


      if (all(is.na(fires_int_all)) || nrow(fires_int_all) == 0) {
        print("No recent fire intensity in area of interest") } else {
          sf::st_write(fires_int_all, file.path(out_path, "fire_int.gpkg"), append = FALSE)
        }

    }
    return(TRUE)
  }


  # 6. download cutblocks

  get_harvest <- function(in_aoi, out_path) {

    file_already_exists <- file.exists(file.path(out_path, "cutblocks.gpkg"))

    if(overwrite == FALSE & file_already_exists == TRUE) {

      message("\r cutblocks already exists, skipping download")

    } else {

      message("\rDownloading cutblock layers")

      cutblocks <- bcdata::bcdc_query_geodata("b1b647a6-f271-42e0-9cd0-89ec24bce9f7") %>%
        bcdata::filter(bcdata::INTERSECTS(in_aoi)) %>%
        bcdata::select(c("HARVEST_YEAR")) %>%
        bcdata::collect()

    if (all(is.na(cutblocks)) || nrow(cutblocks) == 0) {
        print("No recent cutblocks disturbance in area of interest") } else {
    sf::st_write(cutblocks, file.path(out_path, "cutblocks.gpkg"), append = FALSE)
        }

    }
    return(TRUE)
    }

  # 7. download DEM via CDED package

    get_dem <- function(in_aoi, out_path){

      file_already_exists <- file.exists(file.path(out_path, "dem.tif"))

      if(overwrite == FALSE & file_already_exists == TRUE) {

        message("\r dem already exists, skipping download")

      } else {

      trim <- bcmaps::cded_terra(in_aoi)
      #trim <- terra::rast(trim_raw)

      #write out dem # in case
      terra::writeRaster(trim, file.path(out_path, "dem.tif"), overwrite = TRUE)

      # generate slope
      rslope <- terra::terrain(trim, v = "slope", neighbors = 8, unit = "degrees")

      #write out dem # in case
      terra::writeRaster(rslope, file.path(out_path, "slope.tif"), overwrite = TRUE)

      }
      return(TRUE)
    }

    message("\rstart downloading data")

    get_VRI(in_aoi, out_path)
    get_water(in_aoi, out_path)
    get_harvest(in_aoi, out_path)
    get_streams(in_aoi, out_path)
    get_fires(in_aoi, out_path)
    get_fire_intensity(in_aoi, out_path)
    get_dem(in_aoi, out_path)

    message("\rBasedata downloaded")

}
