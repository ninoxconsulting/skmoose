#' Merge habitat areas
#'
#' @param tmp_aoi sf object with aoi of interest
#' @param temp_out_dir file path where all prepared spatial files
#'
#' @return TRUE
#' @export
#'
#' @examples
#' \dontrun{
#' merge_nonhabitat(tmp_aoi, temp_out_dir)
#' }

merge_habit <- function(tmp_aoi, temp_out_dir) {


  hab_sf <- c("vri_decid.gpkg",
                  "cutblocks_filtered.gpkg",
                  "fires_filtered.gpkg",
                  "streams3_8.gpkg",
                  "streams9.gpkg",
                  "wetland.gpkg",
                  "smalllakes.gpkg")


  if(any(hab_sf %in% list.files(temp_out_dir))){
    print("contains uninhabitable areas")

    # create blank sf object to add to
    hab <-  sf::st_sf(st_sfc(), crs = 3005)

    # check deciduous
    if(file.exists(file.path(temp_out_dir,"vri_decid.gpkg"))){
      decid <- sf::st_read(file.path(temp_out_dir,"vri_decid.gpkg"))
      hab<- rbind(decid, hab)
      hab <- sf::st_union(hab)
    }

    # check recent cutblocks
    if(file.exists(file.path(temp_out_dir,"cutblocks_filtered.gpkg"))){
      harvest<- sf::st_read(file.path(temp_out_dir,"cutblocks_filtered.gpkg"))
      hab <- sf::st_union(harvest,hab)
      hab <- sf::st_union(hab)
    }

    # check fires
    if(file.exists(file.path(temp_out_dir,"fires_filtered.gpkg"))){
      fires <- sf::st_read(file.path(temp_out_dir,"fires_filtered.gpkg"))
      hab <- sf::st_union(fires, hab)
      hab <- sf::st_union(hab)
    }

    # check streams 3 - 8
    if(file.exists(file.path(temp_out_dir,"streams3_8.gpkg"))){
      st38<- sf::st_read(file.path(temp_out_dir,"streams3_8.gpkg"))
      hab  <- sf::st_union(st38, hab)
      hab <- sf::st_union(hab)
    }

    # check streams 9
    if(file.exists(file.path(temp_out_dir,"streams9.gpkg"))){
      st9 <- sf::st_read(file.path(temp_out_dir,"streams9.gpkg"))
      hab  <- sf::st_union(st9, hab)
      hab <- sf::st_union(hab)
    }


    # check wetlands
    if(file.exists(file.path(temp_out_dir,"wetland.gpkg"))){
      wet<- sf::st_read(file.path(temp_out_dir,"wetland.gpkg"))
      hab  <- sf::st_union(wet, hab)
      hab <- sf::st_union(hab)
    }


    # crop to the study area
    hab_all = sf::st_intersection(hab, tmp_aoi)
    st_write(hab_all, file.path(temp_out_dir, "habitable.gpkg"),
             append = FALSE)

    #return(unhab_all)

  } else {

    print("no habitable area found")

  }
  return(TRUE)
}

