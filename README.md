# PTAL study of the Netherlands
Vereniging Deltametropool have appointed Arup to perform a PTAL analysis for the Netherlands. PTAL score is calculated for 43,377 centroids derived from of a 500 metre by 500 metre grid produced by the Central Bureau of Statistics (CBS, 2018). Based on the network of pedestrian and cycle paths and General Transit Feed Specification information regarding public transport services, each of these points is scored according the walking or cycling time to nearest stops and stations and service waiting times for bus, tram, metro and train. 

## Approach
The process leading to the final PTAL analysis results can be described in 10 steps.

###	Data collection
The following datasets have been collected as input for the analysis.
###Top10NL wegdeel road network
The Top10NL is created by Kadaster (Kadaster, 2017) contains various layers including ‘wegdeel’; line-geometry based dataset of all road segments with attribute information such as the type of traffic. This information forms the basis for the road network through which pedestrians and cyclists are able to reach the transport nodes.
### CBS 500m grid
The Dutch Central Bureau of Statistics (CBS) uses grids of 500 meter by 500 meter squares to highlight the geographical distribution of their statistical information (CBS, 2018). The PTAL analysis needs a collection of origins for which the accessibility to public transport is measured. For this analysis the centroids of these grids are used. The results of the analysis are highlighted using the squares in a colour-range depicting the different PTAL levels.
### General Transit Feed Specification (GTFS) 
9292 continuously collects GTFS data for all public transport services in the Netherlands.  This information contains the scheduling of the public transport services and is divided up into different elements (9292, 2014).
###Create road network
This process removed road segments that are ‘off-road’, dedicated bus lane or part of airport of other private circuit. Furthermore, information is added highlighting whether the road can be used by cars, cyclists and/or pedestrians based on the road traffic category. 
###Create public transport network 
Within this process the GTFS data is processed. Links between stops are created using stop and trip information. By geo-coding the stop point-based geometry,  the link geometry is added. This allows the visualisation of the public transport network. Stops of different modes of transport but sharing the same stop name are grouped. These stops form the Service Access Points (SAP)
###Walking and cycling isochrones
The road network is transformed into a topological network which allows network analysis such as isochrone analysis. Isolated segment that do not connect to the wider network are discarded. For each SAP the two nearest points within 200 metres on the network are located. These points form the origin of the isochrone analysis. 
For the segments surrounding the origins the distance to these origins are calculated. The maximum radius around the origins depends whether it is a train station, metro station, bus or tram station. The following tables summarise the radius thresholds used. Note that these walking distance thresholds differ from thresholds used in the official TfL PTAL studies.
###	PTAL Points of Interest (POI)
PTAL values are calculated for specific points or locations. In order to highlight PTAL values across the whole of the Netherlands many locations need to be considered. For this study the centroids of the CBS 500 metres by 500 metres grid is used as the collection of points of interest (POI). The points are linked to nearest network segment within a 500 metres search radius. If no network segment is found the point is discarded since no SAP will be in reach. Note that the centroids are relatively arbitrary and do not necessarily link to relevant network segments.
### Link SAP to isochrones
For each POI all the SAPs are identified that are within the specific walking and/or cycling distance depending on the type of the stop. The minimum distance from the POI to the SAP is calculated. 
###Public transport routes per SAP
Using the schedule information of the public transport services, the frequency of services is determined by summing up the number of trips per SAP between 17:00 and 18:00 on weekdays. From bi-directional trips only the direction with the highest frequency is regarded.
###Route time analysis
A number of time analyses per routes are calculated that form the basis of the final PTAL measure.
* Travel time = Distance from POI to SAP x 80 metres/minute (walking) or 300 metres/minute (cycling)
* Service Waiting Time (SWT) =  0.5 x (60/frequency)
* Average Waiting Time (AWT) = SWT + 0.75 (train) or 2 (other modes).
* Total Access Time (TAT)  = Travel time + AWT
* Equivalent Doorstep Frequency (EDF) = 0.5 x (60/TAT)
* Access Index (AI) = Largest EDF + 0.5 * ∑(all other EDFs)
* Public Transport Accessibility Index (PTAI) =  ∑(AIbus + AIrail + AImetro + AItram + AIveerboot)

The final PTAL is determined by converting the PTAI into the following value ranges. PTAL values from this analysis cannot be compared to TfL PTAL studies directly since different walking distance thresholds to SAPs have been used. 

###Grid visualisation
The final PTAL and PTAI values are linked to the original CBS grid cells. These cells along with their attribute information are shared as a compressed ESRI shapefile; the key deliverable of this study.

The results of this study is a PTAL analysis that covered the whole of the Netherlands. The performed analysis heavily relies on the scripts developed by Jorge Gil Consulting as part of the Informatie Systeem Knooppunten project on behalf of Vereniging Deltametropool (Gil, 2017). Adaptations have been made in order to address the large scale of the analysis. For further information regarding the exact calculations please refer to the documentation on Github and TfL website. 
##Limitations
Although the PTAL analysis has been performed successfully, some limitations remain.
* TOP10NL network has proven to contain disconnected segments. Other errors might still remain. Ferry connections are also known to have disconnections resulting in inaccurate ferry service representation. Some cycle and walking path are missing. A thorough review of this network as well as the integration of missing network connections to fully represent walking and cycling linkages is needed.
* PTAL values do differentiate between different modes of transport. A train service is treated equally to a bus service. The geographical concentration as well the combined frequency of these services do count. PTAL analysis is originally an city-based analysis. Perhaps the specified PTAL ranges as well used assumptions and calculations need to be reviewed in order to depict the level of access to public transport services on a national scale. 
The CBS grid resolution is 500 metres by 500 metres. Ideally this would have been 100 metres by 100 metres. This not possible with the current analysis processing capacity.  
##Testing and verification
A detailed analysis resulted in a number of issues: . 
1.	Areas around the RandstadRail stations have moderate to low PTAL values. This is because chosen POIs along the Randstadrail have long walking times to the stations. Furthermore, surrounding bus services operate with frequencies.
2.	Scheveningen region has high PTAL levels because there is a high concentration of tram and bus stops that operate with high frequencies. PTAL analysis does not favour one mode such as train over another mode such as bus. 
3.	Hoek van Holland shows low PTAL levels because GTFS data which has been sourced covers the period between 30th of April 2018 and 31st of March 2019 in which no train or metro services to Hoek van Holland are scheduled. 
4.	Initially the grid cell south of Delft Zuid train station did not have a PTAL value. This was due to isolated segments in the TOP10NL wegdeel network. The analysis has adopted an algorithm that filters these segments which has solved this issue.
Other undefined issues might still be present. If the agreed scope allows, these issues will be reviewed by Arup and efforts to adjust the analysis will be made. 
