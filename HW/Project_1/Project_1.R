# Matt Crittenden
# DATA 440 - ABM
# Sept 18 2020 (created)
# Sept 18 2020 (edited)
# Project 1

# Notes: This script exists because I needed to recreate my geometrics bar plots / map to describe
#  Zimbabwe, as I had only tested with Cuba before. Otherwise, the remainder of the code can be found
#  in the 2.3_Accessibility_123 folder.

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



# other steps found at accessibility_1.R