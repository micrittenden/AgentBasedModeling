# Accessibility 1, 2, & 3

### Part One: Creating De Facto Urban Settlements

First, I created de facto urban settlements in Seke, Zimbabwe using synthetic population data produced with original population data for 2020. With a sigma value of 0.002489435, I drew contour lines around the most densely populated areas, then removed those which were noisy (too low population, too low/high density). The map below shows the density and populations of these settlements.

![Image of pop raster](https://github.com/micrittenden/Data440-AgentBasedModelling/blob/master/HW/2.3_Accessibility_123/seke_pop20_w0.png)

![Image of ppp](https://github.com/micrittenden/Data440-AgentBasedModelling/blob/master/HW/2.3_Accessibility_123/seke_ppp_w0.png)

![Image of settlements](https://github.com/micrittenden/Data440-AgentBasedModelling/blob/master/HW/2.3_Accessibility_123/seke_test.png)

### Part Two: Adding Connective and Health Infrastructure Data

Then, I added data on roads (primary, secondary, and nonclassified) from the World Bank (https://datacatalog.worldbank.org/dataset/zimbabwe-roads-0) and data on health facilities (hospitals and clinics) from a spatial inventory of public health facilities in sub Saharan Africa covering 49 countries (https://www.nature.com/articles/s41597-019-0142-2).

![Image of roads and health facilities](https://github.com/micrittenden/Data440-AgentBasedModelling/blob/master/HW/2.3_Accessibility_123/seke_health.png)

### Part Three: Adding Topographical Data

Finally, I added a 30-meter-resolution DEM of Zimbabwe, cropped to the boundary of Seke district. The final 3D map includes roads in orange (scaled in size) and health facilities in red (points denoting hospitals are slightly larger than those for clinics)

![Image of 3D plot](https://github.com/micrittenden/Data440-AgentBasedModelling/blob/master/HW/2.3_Accessibility_123/seke_3d.png)
