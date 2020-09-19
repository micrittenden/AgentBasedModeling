# Matt Crittenden
# DATA 440 - ABM
# Sept 18 2020 (created)
# Sept 18 2020 (edited)
# Project 1


#---import packages-----

library(tidyverse)
library(sf)
library(raster)
library(doParallel)
library(snow)
library(units)
library(ggpubr)
library(maptools)
library(spatstat)
library(rayshader)
library(rayrender)


#---set wd and import data-----

setwd("~/William_and_Mary/WM_Year4Fall2020/ABM/HW/Project_1")

zwe_adm1 <- read_sf("./data/gadm36_ZWE_shp/gadm36_ZWE_1.shp")
zwe_adm2 <- read_sf("./data/gadm36_ZWE_shp/gadm36_ZWE_2.shp")

zwe_pop20 <- raster("./data/zwe_ppp_2020.tif")

zwe_roads <- read_sf("./data/zwe_roads/Final_Zimbabwe_Roads_Version01.shp")

afr_health <- readxl::read_xlsx("./data/health_facilities.xlsx")

zwe_elevation <- raster("./data/zwe_SRTM_DEM_30_m.tiff")


#---plot population density across ADM1s in the country-----

masheast <- zwe_adm2 %>%
  filter(NAME_1 == "Mashonaland East")

masheast_pop20 <- crop(zwe_pop20, masheast)
masheast_pop20 <- mask(masheast_pop20, masheast)

# ncores <- detectCores() - 1
# beginCluster(ncores)
# pop_vals_adm1 <- raster::extract(masheast_pop20, masheast, df = TRUE)
# endCluster()
# save(pop_vals_adm1, file = "pop_vals_adm1.RData")

load("pop_vals_adm1.RData")

totals_adm1 <- pop_vals_adm1 %>%
  group_by(ID) %>%
  summarize(pop20 = sum(zwe_ppp_2020, na.rm = TRUE))

masheast <- masheast %>%
  add_column(pop20 = totals_adm1$pop20)

ggplot(masheast) +
  geom_sf(aes(fill = pop20)) +
  geom_sf_text(aes(label = NAME_2),
               color = "black",
               size = 2) +
  scale_fill_gradient(low = "yellow", high = "red")

# ggsave("masheast_pop20.png")

# save(masheast, file = "masheast_pop20.RData")

# load("masheast_pop20.RData")

masheast <- masheast %>%
  mutate(area = sf::st_area(masheast) %>%
           units::set_units("km^2")) %>%
  mutate(density = pop20/area)

bar <- masheast %>%
  mutate(NAME_2 = fct_reorder(NAME_2, pop20)) %>%
  ggplot(aes(x=NAME_2, y=pop20, fill=pop20)) +
  geom_bar(stat="identity", color="gray35", width=0.7) +
  coord_flip() +
  xlab("provinces") + ylab("population") +
  geom_text(aes(label=scales::percent(pop20/sum(pop20))),
            position = position_stack(vjust = 0.5),
            color = "black", size=4) +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle(label="Population & share of Population (in %)")


map <- ggplot(masheast) +
  geom_sf(aes(fill = pop20)) +
  geom_sf_text(aes(label = NAME_2),
               color = "black",
               size = 4) +
  geom_sf_text(aes(label = round(density, 2)),
               color = "black",
               size = 4, nudge_y = -0.1) +
  xlab("longitude") + ylab("latitude") +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle(label="Population & Density in persons / km^2")



masheast_duo<- ggarrange(map, bar, nrow = 1, widths =c(3, 1.5))
annotate_figure(masheast_duo, top = text_grob("Mashonaland East in 2020", color = "black", face = "bold"))


#ggsave("masheast_duo.png", width = 15, height = 10, dpi = 200)



#---Redo Accessibility 1,2,3 stuff from before w lower levels to generate more -----

seke <- zwe_adm2 %>%
  filter(NAME_1 == "Mashonaland East") %>%
  filter(NAME_2 == "Seke")

seke_pop20 <- crop(zwe_pop20, seke)
seke_pop20 <- mask(seke_pop20, seke)
seke_pop20[is.na(seke_pop20)] <- 0          #solves later problem of lakes breaking de facto population boundaries
pop <- floor(cellStats(seke_pop20, 'sum'))

#plot and create pdf
#png("seke_pop20_w0.png", width = 800, height = 800)
plot(seke_pop20, main = NULL)
plot(st_geometry(seke), add = TRUE)
#dev.off()

#make version of seke which is compatible with spatstat
st_write(seke, "./data/seke/seke.shp", delete_dsn=TRUE)
seke_with_mtools <- readShapeSpatial("./data/seke/seke.shp")

#create window object to be used with rpoint
win <- as(seke_with_mtools, "owin")

# seke_ppp <- rpoint(pop, f = as.im(seke_pop20), win = win)
# save(seke_ppp, file = "./data/seke_ppp.RData")
load("./data/seke_ppp.RData")

#plot and create pdf
#png("seke_ppp_w0.png", width = 2000, height = 2000)
plot(win, main = NULL)
plot(seke_ppp, cex = 0.15, add = TRUE)
#dev.off()


#---calculate bandwidth, run spatial density function, and create polygons-----

# bw_0 <- bw.ppl(seke_ppp)
# save(bw_0, file = "./data/bw_0.RData")
load("./data/bw_0.RData")

seke_dens <- density.ppp(seke_ppp, sigma = bw_0)

#png("seke_dens.png", width = 1200, height = 1200)
plot(seke_dens, main = NULL)
#dev.off()

#set contour line threshold
Dsg <- as(seke_dens, "SpatialGridDataFrame")  # convert to spatial grid class
Dim <- as.image.SpatialGridDataFrame(Dsg)  # convert again to an image
Dcl <- contourLines(Dim, levels = 600000)  # create contour object
SLDF <- ContourLines2SLDF(Dcl, CRS("+proj=longlat +datum=WGS84 +no_defs"))

SLDFs <- st_as_sf(SLDF, sf)

#png("seke_dsg_conts.png", width = 1200, height = 1200)
plot(Dsg)
plot(SLDFs, add = TRUE)
#dev.off()

#convert contour lines to polygons
inside_polys <- st_polygonize(SLDFs)
outside_lines <- st_difference(SLDFs, inside_polys)
outside_buffers <- st_buffer(outside_lines, 0.001)
outside_intersects <- st_difference(seke, outside_buffers)

oi_polys <- st_cast(outside_intersects, "POLYGON")
in_polys <- st_collection_extract(inside_polys, "POLYGON")

#remove all columns that are not geometries
in_polys[,1] <- NULL
oi_polys[,1:15] <- NULL

#combine polys
all_polys <- st_union(in_polys, oi_polys)
all_polys <- st_collection_extract(all_polys, "POLYGON")
all_polys <- st_cast(all_polys, "POLYGON")
all_polys_seke <- all_polys %>%
  unique()

#calculate area
all_polys_seke$area <- as.numeric(st_area(all_polys_seke))

all_polys_seke <- all_polys_seke %>%
  filter(area < 2500000000)

#---extract population values, group by urban areas, sum pop totals-----

all_polys_seke_ext <- raster::extract(seke_pop20, all_polys_seke, df = TRUE)

all_polys_seke_ttls <- all_polys_seke_ext %>%
  group_by(ID) %>%
  summarize(pop20 = sum(zwe_ppp_2020, na.rm = TRUE))

all_polys_seke <- all_polys_seke %>%
  add_column(pop20 = all_polys_seke_ttls$pop20) %>%
  mutate(area = as.numeric(st_area(all_polys_seke) %>%
                             units::set_units(km^2))) %>%
  mutate(density = as.numeric(pop20/area))

#remove some with unrealistic values created by noise
all_polys_seke <- all_polys_seke %>%
  filter(pop20 > 100)

#add an intermediary step which gets rid of mess ups

all_polys_seke <- all_polys_seke %>%
  mutate(temp_label = sample(1:nrow(all_polys_seke), nrow(all_polys_seke), replace = FALSE))

ggplot() +
  geom_sf(data = all_polys_seke) +
  geom_sf_label(data = all_polys_seke,
                aes(label = temp_label))

#this part may need to change each time
all_polys_seke <- all_polys_seke %>%
  filter(temp_label != 13) %>%
  filter(temp_label != 15)

all_polys_seke <- all_polys_seke[,-5]

#crop the polys to shape of seke
all_polys_seke_crop <- st_intersection(all_polys_seke, seke)

#---plot-----

#create center points
seke_cntr_pts <-  all_polys_seke_crop %>% 
  st_centroid() %>% 
  st_cast("MULTIPOINT")

#plot
ggplot() +
  geom_sf(data = seke,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_seke_crop,
          fill = "lightblue",
          size = 0.25,
          alpha = 0.5) +
  geom_sf(data = seke_cntr_pts,
          aes(size = pop20,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Urbanized Areas throughout Seke, Zimbabwe")

#ggsave("seke_settlements.png", width = 10, height = 10)


#---ACCESSIBILITY 2-----

#---roads-----

#crop roads
seke_roads <- st_crop(zwe_roads, seke)

#create separate objects by road class
primary_roads <- seke_roads %>%
  filter(CLASS == "Primary")

secondary_roads <- seke_roads %>%
  filter(CLASS == "Secondary")

nonclassified_roads <- seke_roads %>%
  filter(CLASS == "Non Classified")


#plot roads
ggplot() +
  geom_sf(data = seke,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_seke_crop,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = primary_roads,
          size = 1,
          color = "orange") +
  geom_sf(data = secondary_roads,
          size = 0.5,
          color = "orange") +
  geom_sf(data = nonclassified_roads,
          size = 0.1,
          color = "orange") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Roadways throughout Seke")

#ggsave("seke_roads.png", width = 10, height = 10)


#---health care facilities-----

afr_health <- afr_health[!is.na(afr_health$Lat),]
afr_health <- afr_health[!is.na(afr_health$Long),]
afr_xy <- afr_health[,c(7,6)]
afr_xy <- as.data.frame(afr_health)
afr_sf <- st_as_sf(afr_xy, coords = c("Long","Lat"), crs = 4326)
seke_health <- st_crop(afr_sf, seke)


hospitals <- seke_health %>%
  filter(grepl("Hospital", `Facility type`))

clinics <- seke_health %>%
  filter(grepl("Clinic", `Facility type`))

#plot health care facilities
ggplot() +
  geom_sf(data = seke,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = all_polys_seke_crop,
          size = 0.75,
          color = "gray50",
          fill = "gold3",
          alpha = 0.15) +
  geom_sf(data = primary_roads,
          size = 1,
          color = "orange") +
  geom_sf(data = secondary_roads,
          size = 0.5,
          color = "orange") +
  geom_sf(data = nonclassified_roads,
          size = 0.1,
          color = "orange") +
  geom_sf(data = hospitals,
          size = 2,
          color = "blue") +
  geom_sf(data = clinics,
          size = 1,
          color = "blue") +
  geom_sf(data = seke_cntr_pts,
          aes(size = pop20,
              color = density),
          show.legend = 'point') +
  scale_color_gradient(low = "yellow", high = "red") +
  xlab("longitude") + ylab("latitude") +
  ggtitle("Access to Health Care Services throughout Seke")

#ggsave("seke_health.png", width = 10, height = 10)


#---ACCESSIBILITY 3-----

#---topography-----

#crop DEM to seke
seke_topo <- crop(zwe_elevation, seke)

#convert raster to matrix
seke_topo_matrix <- raster_to_matrix(seke_topo)


#plot (3D)

# seke_topo_matrix %>%
#   sphere_shade() %>%
#   add_water(detect_water(seke_topo_matrix)) %>%
#   plot_map()

ambientshadows <- ambient_shade(seke_topo_matrix)

seke_topo_matrix %>%
  sphere_shade(texture = "imhof3") %>%
  add_water(detect_water(seke_topo_matrix)) %>%
  add_shadow(ray_shade(seke_topo_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(seke_topo_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  plot_3d(seke_topo_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.5, 
          background = "grey30", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)

render_snapshot(title_text = "Seke, Zimbabwe", 
                title_size = 50,
                title_color = "grey90")


seke_outline <- ggplot() +
  geom_sf(data = seke,
          size = 4,
          linetype = "11",
          color = "gold",
          alpha = 0) +
  geom_sf(data = all_polys_seke_crop,
          size = 0.75,
          color = "gray50",
          fill = "orange",
          alpha = 0.5) +
  geom_sf(data = primary_roads,
          size = 2,
          color = "orange") +
  geom_sf(data = secondary_roads,
          size = 1,
          color = "orange") +
  geom_sf(data = nonclassified_roads,
          size = 0.5,
          color = "orange") +
  geom_sf(data = hospitals,
          size = 4,
          color = "red") +
  geom_sf(data = clinics,
          size = 2,
          color = "red") +
  theme_void() + theme(legend.position="none") +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  labs(x=NULL, y=NULL, title=NULL)

#png("seke_outline.png", width = 920, height = 1136, units = "px", bg = "transparent")
seke_outline
#dev.off()

overlay_img <- png::readPNG("seke_outline.png")

seke_topo_matrix %>%
  #sphere_shade(texture = "imhof3") %>%
  sphere_shade() %>%
  add_water(detect_water(seke_topo_matrix)) %>%
  add_shadow(ray_shade(seke_topo_matrix, sunaltitude = 3, zscale = 33, lambert = FALSE), max_darken = 0.5) %>%
  add_shadow(lamb_shade(seke_topo_matrix, sunaltitude = 3, zscale = 33), max_darken = 0.7) %>%
  add_shadow(ambientshadows, max_darken = 0.1) %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  plot_3d(seke_topo_matrix, zscale = 20,windowsize = c(1000,1000), 
          phi = 40, theta = 135, zoom = 0.8, 
          background = "grey30", shadowcolor = "grey5", 
          soliddepth = -50, shadowdepth = -100)

#png("seke_3d.png", width = 1000, height = 1000)
render_snapshot(title_text = "Seke, Zimbabwe", 
                title_size = 50,
                title_color = "grey90")
#dev.off()

