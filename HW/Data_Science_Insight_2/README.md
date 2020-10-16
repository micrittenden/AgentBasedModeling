# Data Science Insight 2

### Li et al. "A harmonized global nighttime light dataset 1992-2018." Nature 7, no. 168 (2020): 1-9. [https://doi.org/10.1038/s41597-020-0510-y](https://doi.org/10.1038/s41597-020-0510-y).

#### Background information:

In economic development, nighttime light data is used as a proxy for traditional measures of income. This is because it can be very expensive to collect survey data on income and quality of life at the household level. By looking at which houses are lit at night, one can approximate the economic standing of the broader community. At aggregate, one can study the economic standing of districts, regions, and even countries relative to each other. Nighttime lights data can quantitatively describe the intensity of socioeconomic activities and urbanization. The map of nighttime lights below reflects the drastic difference between MDCs and LDCs, with NICs somewhere in between.

![NTL Image from NASA](ntl_2016.jpg)
Image from [NASA](https://www.nasa.gov/feature/goddard/2017/new-night-lights-maps-open-up-possible-real-time-applications).

#### Introducing the study:

However, using nighttime light data involves a few challenges, beyond just possessing the computational skills. One challenge is collecting standardized data. The Defense Meteorological Satellite Program (DMSP) provided public data up to 2013, but has since not publically released its data, limiting the use of DMSP data in urban, development, and economic studies. Visible Infrared Imaging Radiometer Suite (VIIRS) data has proven to be an effective source for recent nighttime light-based studies (measures radiance) with greater resolution than earlier DMSP data, but it is only available since 2012. The two datasets are incompatible in their raw forms. In their paper, Li et al attempt to solve the data challenge by harmonizing the nighttime lights observations from DMSP and VIIRS data.

To do so, they start with DMSP data from 1992 to 2013 and VIIRS data from 2014 to 2018. There are two main difficulties to confront. First, the DMSP data needs to be inter-calibrated globally. Second, they need to convert the VIIRS radiance data to DMSP-like data.

#### Framework (with some math which is above my head):

(1) Composite annual VIIRS data from monthly observations and remove noise.
![function 1](fun1.jpg)
![image 1](img1.jpg)
(2) Quantify the relationship between processed VIIRS data and DMSP data using a sigmoid function.
![function 2](fun2.jpg)
![image 2](img2.jpg)
(3) Apply the derived relationship at the global scale to obtain the DMSP-like data for years 2014-2018. See the [original article](https://doi.org/10.1038/s41597-020-0510-y) for the intermediate steps and exact calculations.
![image 3](img3.jpg)

#### Accessing the harmonized nighttime lights data:

The harmonized global NTL data from 1992 to 2018 can be found at the [figshare repository](https://doi.org/10.6084/m9.fgshare.9828827.v2) tagged in GEOTIFF file format. These data can be processed by standard GIS software (e.g., QGIS).