# Matt Crittenden
# DATA 440 - ABM
# Aug 26 2020
# Spatial population description

#---import packages-----

library(tidyverse)
library(sf)
library(raster)
library(doParallel)
library(snow)
library(units)
library(ggpubr)

#---set wd and import data-----

setwd("~/William_and_Mary/WM_Year4Fall2020/ABM/HW/Spatial_population_statistics")


lbr_int <- read_sf("./data/gadm36_LBR_shp/gadm36_LBR_0.shp")
lbr_adm1 <- read_sf("./data/gadm36_LBR_shp/gadm36_LBR_1.shp")
lbr_adm2 <- read_sf("./data/gadm36_LBR_shp/gadm36_LBR_2.shp")

mng_int <- read_sf("./data/gadm36_MNG_shp/gadm36_MNG_0.shp")
mng_adm1 <- read_sf("./data/gadm36_MNG_shp/gadm36_MNG_1.shp")
mng_adm2 <- read_sf("./data/gadm36_MNG_shp/gadm36_MNG_2.shp")

CUB_int <- read_sf("./data/gadm36_CUB_shp/gadm36_CUB_0.shp")
#CUB_adm1 <- read_sf("./data/gadm36_CUB_shp/gadm36_CUB_1.shp")
CUB_adm2 <- read_sf("./data/gadm36_CUB_shp/gadm36_CUB_2.shp")



#---liberia map 1-----

ggplot() +
  geom_sf(data = lbr_int,
          size = 1.5,
          color = "gold",
          fill = "green",
          alpha = 0.5) +
  geom_sf_text(data = lbr_int,
               aes(label = "Liberia"),
               size = 4,
               color = "blue")


ggplot() +
  geom_sf(data = lbr_adm1,
          size = 0.65,
          color = "gray50",
          fill = "gold3",
          alpha = 0.65) +
  geom_sf(data = lbr_int,
          size = 2,
          color = "black",
          fill = "green",
          alpha = 0) +
  geom_sf_text(data = lbr_adm1,
               aes(label = lbr_adm1$NAME_1),
               size = 2,
               color = "white") +
  geom_sf_text(data = lbr_int,
               aes(label = "Liberia"),
               size = 5,
               color = "black")
  

ggplot() +
  geom_sf(data = lbr_adm2,
          size = 0.5,
          color = "gray50",
          fill = "gold3",
          alpha = 0.65) +
  geom_sf(data = lbr_adm1,
          size = 1,
          color = "gray50",
          fill = "gold3",
          alpha = 0) +
  geom_sf(data = lbr_int,
          size = 2,
          color = "black",
          fill = "green",
          alpha = 0) +
  geom_sf_text(data = lbr_adm2,
               aes(label = lbr_adm2$NAME_2),
               size = 1,
               color = "black") +
  geom_sf_text(data = lbr_adm1,
               aes(label = lbr_adm1$NAME_1),
               size = 2,
               color = "black")

# ggsave("liberia.png")


#---mongolia map 1-----

ggplot() +
  geom_sf(data = mng_adm2,
          size = 0.5,
          color = "gray50",
          fill = "gold3",
          alpha = 0.65) +
  geom_sf(data = mng_adm1,
          size = 1,
          color = "gray35",
          fill = "gold3",
          alpha = 0) +
  geom_sf(data = mng_int,
          size = 2,
          color = "black",
          fill = "green",
          alpha = 0) +
  geom_sf_text(data = mng_adm2,
               aes(label = mng_adm2$NAME_2),
               size = 1,
               color = "gray35") +
  geom_sf_text(data = mng_adm1,
               aes(label = mng_adm1$NAME_1),
               size = 2,
               color = "black") +
  ggtitle(label = "Administrative Boundaries of Mongolia")

# ggsave("mongolia.png")




#---extracting populations from raster and agg-----


cub_pop19 <- raster("./data/worldpop/cub_ppp_2019.tif")

plot(cub_pop19)
plot(st_geometry(CUB_adm1), add = TRUE)


# ncores <- detectCores() - 1
# beginCluster(ncores)
# pop_vals_adm1 <- raster::extract(cub_pop19, CUB_adm1, df = TRUE)
# endCluster()
# save(pop_vals_adm1, file = "pop_vals_adm1.RData")

load("pop_vals_adm1.RData")

totals_adm1 <- pop_vals_adm1 %>%
  group_by(ID) %>%
  summarize(pop19 = sum(cub_ppp_2019, na.rm = TRUE))

CUB_adm1 <- CUB_adm1 %>%
  add_column(pop19 = totals_adm1$pop19)

ggplot(CUB_adm1) +
  geom_sf(aes(fill = pop19)) +
  geom_sf_text(aes(label = NAME_1),
               color = "black",
               size = 2) +
  scale_fill_gradient(low = "yellow", high = "red")

# ggsave("cub_pop19.png")

# save(CUB_adm1, file = "CUB_adm1_pop19.RData")

# load("CUB_adm1_pop19.RData")

CUB_adm1 <- CUB_adm1 %>%
  mutate(area = sf::st_area(CUB_adm1) %>%
           units::set_units("km^2")) %>%
  mutate(density = pop19/area)

bar <- CUB_adm1 %>%
  mutate(NAME_1 = fct_reorder(NAME_1, pop19)) %>%
  ggplot(aes(x=NAME_1, y=pop19, fill=pop19)) +
  geom_bar(stat="identity", color="gray35", width=0.7) +
  coord_flip() +
  xlab("provinces") + ylab("population") +
  geom_text(aes(label=scales::percent(pop19/sum(pop19))),
            position = position_stack(vjust = 0.5),
            color = "black", size=2.0) +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle(label="Population & share of Population (in %)")


map <- ggplot(CUB_adm1) +
  geom_sf(aes(fill = pop19)) +
  geom_sf_text(aes(label = NAME_1),
               color = "black",
               size = 2) +
  geom_sf_text(aes(label = round(density, 2)),
               color = "black",
               size = 2, nudge_y = -0.1) +
  xlab("longitude") + ylab("latitude") +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle(label="Population & Density in persons / km^2")



cuba<- ggarrange(map, bar, nrow = 1, widths =c(3, 1.5))
annotate_figure(cuba, top = text_grob("Cuba in 2019", color = "black", face = "bold"))


# ggsave("cuba_duo.png", width = 20, height = 10, dpi = 200)
