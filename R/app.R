library(shiny)
library(DT)
library(ggplot2)
library(data.table)
library(ggmap)
library(shinythemes)
library(leaflet)

ui <- navbarPage("USAF:OEA", 
                 #Executive Dashboard
                    tabPanel("Executive",
                        fluidRow(
                            column(2,
                                   img(height=200, width=200, src="AF OEA.png")),
                             column(10, 
                                    br(),
                                    br(),
                                   h1("United States Air Force: Office of Energy Assurance"),
                                   h3("Device ManageR - Executive Dashboard"))
                        ),
                        fluidRow(
                            column(width = 12,
                                 h4("Count of Abnormal Readings", style="color:#FFFFFF;"),
                                 h6("(Last 1.5 Minutes)", style="color:#FFFFFF;"),
                                 style ="background-color:#2C001E;")
                        ),
                          fluidRow(
                            column(width=2,
                                   h6(strong("New York"), style="color:#FFFFFF;"),
                                   h2(textOutput("cellNY"), style="color:#FFFFFF;"),
                                   style ="background-color:#2C001E;", offset = 1),
                            column(width=2, 
                                   h6(strong("Atlanta"), style="color:#FFFFFF;"),
                                   h2(textOutput("cellATL"), style="color:#FFFFFF;"),
                                   style ="background-color:#411934;"),
                            column(width=2,
                                   h6(strong("Boston"), style="color:#FFFFFF;"),
                                   h2(textOutput("cellBOS"), style="color:#FFFFFF;"),
                                   style ="background-color:#56334B;"),
                            column(width=2, 
                                   h6(strong("Seattle"), style="color:#FFFFFF;"),
                                   h2(textOutput("cellSTL"), style="color:#FFFFFF;"),
                                   style ="background-color:#6B4C61;"),
                            column(width=2, 
                                   h6(strong("Denver"), style="color:#FFFFFF;"),
                                   h2(textOutput("cellDEN"), style="color:#FFFFFF;"),
                                   style ="background-color:#806678;"),
                            style ="background-color:#2C001E;"
                        ),
                        hr(),
                          fluidRow(
                            column(width = 3,
                                   p("The summary table provides the full record of sensor operations for the entire
                                     sensor system."),
                                   br(),
                                   p("Toggle the Time Range to filter the results on the Key Performance Indicators table."),
                                   br(),
                                   p("Table Elements:"),
                                   br(),
                                   p("Count of Readings, Average Sensor Reading, Minimum Sensor Reading, Maximum Sensor Reading,
                                     the Percentage Sensor Readings that are Abnormal, the Percentage of Sensor Readings that are Normal.")
                                   ),
                            column(width = 9,
                                   h4("Key Performance Indicators"),
                                   sliderInput("time", label = h6("Time Range"), min=min(master$Sys_Time), 
                                               max = max(master$Sys_Time), 
                                   value = c(min(master$Sys_Time),max(master$Sys_Time))),
                                   dataTableOutput(outputId = "execTable"))
                        ),
                        hr(),
                        fluidRow(
                          column(width = 6,
                                 h4("Comparison of Abnormal & Normal Readings"),
                                 h6("The chart below compares the number of abnormal readings versus normal readings
                                    for each office location."),
                                 plotOutput(outputId = "barGraph")),
                          column(width = 6,
                                 h4("Distribution of Sensor Readings by Location"),
                                 h6("The chart below bins readings by location and plots them vertically according 
                                    to their value."),
                                 plotOutput(outputId = "dotPlot"))
                        ),
                        hr(),
                          fluidRow(
                            column(12,
                                   h3("Machine Performance", style="color:#FFFFFF;"),
                                   style ="background-color:#2C001E;")
                          ),
                        fluidRow(
                          column(width = 2,
                                 selectInput("Location", label = h4("Select Location"), 
                                             choices = c("Boston" = "Boston", "Seattle" = "Seattle", "New York" = "New York","Denver"="Denver","Atlanta" ="Atlanta"), selected = "Boston"),
                                 br(),
                                 p("The drop-down menu above will toggle the visualizations in this segment of the dashboard."),
                                 br(),
                                 p("The histrogram and boxplot chart will enable your ability to assess and compare the performance of every machine for any designated office location.")
                          ),
                          column(width = 8,
                                 h4("Indicators by Element"),
                                 selectInput("factor", label = h6("Select Factor"), 
                                             choices = c("Machine Type"="Machine_Type","Sensor Type"="Sensor_Type",
                                                         "Abnormal?" = "Reading_Flag"), selected = "Machine Type"),
                                 DT::dataTableOutput(outputId = "execChange")) 
                        ),
                          fluidRow(
                            column(8,
                                   h4("Distribution of Sensor Values by Machine"),
                                   p("The plot below shows the variance in sensor readings for each machine at 
                                     the office location selected."),
                                   plotOutput(outputId = "boxplot"), offset = 2)
                            
                          ),
                        fluidRow(
                          column(8,
                                 h4("Sensor Readings Over Time"),
                                 p("The line chart below shows how sensor readings, at the office selected, has varied over time."),
                                 plotOutput(outputId = "line"), offset = 2)
                        ), fluid = TRUE, widths = c(2, 10)
                          ),
                 
                 #Operations Dashboard UI Content
                 tabPanel("Operations",
                      fluidRow(
                            column(2,
                                   img(height=200, width=200, src="AF OEA.png")),
                            column(10, 
                                   br(),
                                   br(),
                                   h1("United States Air Force: Office of Energy Assurance"),
                                   h3("Device ManageR - Operations Dashboard"))
                    ),
                      hr(),
                      fluidRow(
                            column(width = 12,
                                   leafletOutput("map", height="600px"))
                    ),
                      fluidRow(
                            column(width = 6,
                                   h6("Click on the map to select an office location and toggle the options below to change the table"),
                             selectInput("Factor1", label = h5("Machine Factor"), 
                                         choices = c("Machine Type"="Machine_Type", "Machine ID" = "Machine_ID",
                                                     "Sensor Type"="Sensor_Type","Sensor ID" = "Sensor_ID"), 
                                         selected = "Sensor Type"),
                             dataTableOutput("mapTable"))
                    ),
                    hr(),
                    fluidRow(
                      column(12,
                             h3("Sensor Performance", style="color:#FFFFFF;"),
                             style ="background-color:#2C001E;")
                    ),
                      fluidRow(
                            column(width = 2,
                                   uiOutput(outputId="location1"),
                                   uiOutput(outputId="mach"),
                                   br(),
                                   p("Toggle the office location and machine IDs to change the content in the line 
                                     and histogram chart.")),
                            column(width = 10,
                                   h4("Sensor Values Over Time"),
                                   plotOutput(outputId="opline"))
                    ),
                      fluidRow(
                            column(width = 12,
                                   h4("Distribution of Sensor Values by Machine"),
                                   plotOutput(outputId="hist"))
                      )
                ),
                 fluid=TRUE, theme = shinytheme("united"))

server <- function(input, output) {
 #Create a timed process that updates the data on both dashboards
  dataSource <- reactivePoll(60000,NULL,
                      checkFunc = function() {nrow(master)},
                      valueFunc = function() {
                        assign('master',master,envir=.GlobalEnv)
                        master
                      })
  
  #Output code is written the order of appearance
      #Executive Dashboard
                output$cellATL <- renderText({
                  satl <- data.table(tail(dataSource(), 315))
                  satl[Location=="Atlanta",sum(Reading_Flag)]})
                output$cellBOS <- renderText({
                  sbos <- data.table(tail(dataSource(), 315))
                  sbos[Location=="Boston",sum(Reading_Flag)]})
                output$cellDEN <- renderText({
                  sdnv <- data.table(tail(dataSource(), 315))
                  sdnv[Location=="Denver",sum(Reading_Flag)]})
                output$cellNY <- renderText({
                  snyc <- data.table(tail(dataSource(), 315))
                  snyc[Location=="New York",sum(Reading_Flag)]})
                output$cellSTL <- renderText({
                  sstl <- data.table(tail(dataSource(), 315))
                  sstl[Location=="Seattle",sum(Reading_Flag)]})
                
                data <- reactive({dataSource()[which(dataSource()$Sys_Time >=input$time[1] & dataSource()$Sys_Time <= input$time[2]),]})
                
                output$execTable <- DT::renderDataTable({
                    execTable <- data.table(data())
                    DT::datatable(execTable[,{Cnt_Readings=length(Sensor_Value)
                                            Avg_Reading=round(mean(Sensor_Value), digits=2)
                                            Min_Reading = min(Sensor_Value)
                                            Max_Reading = max(Sensor_Value)
                                            Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                            Perc_Normal =(round(1-(mean(Reading_Flag)), digits = 3))*100
                                            list(Cnt_Readings=Cnt_Readings,Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, 
                                                 Max_Reading=Max_Reading,Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)},
                                            by=Location],
                                    options = list(dom ='t'))
                    })
                
                Selected <- reactive({input$Location})
                factorList <- reactive({input$factor})
                
                output$execChange <- DT::renderDataTable({
                data <- dataSource()[dataSource()$Location==Selected(),]
                data <- data.table(data)
                  DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                      Cnt_Abnormal=sum(Reading_Flag)   
                                      Avg_Reading=round(mean(Sensor_Value), digits=2)
                                      Min_Reading = min(Sensor_Value)
                                      Max_Reading = max(Sensor_Value)
                                      Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                      Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                      list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                           Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                           Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                     by=eval(factorList())], 
                      options = list(dom = 't'))
                  })
                
                output$barGraph <- renderPlot({
                  barCompar <- ggplot(dataSource(), aes(Reading_Flag))+geom_bar(aes(fill = Reading_Flag))+
                  facet_grid(. ~Location)+theme(axis.text.x=element_blank())+scale_fill_manual(values=c("#77216F","#2C001E"),name="Sensor Reading Flag", 
                                                                                               breaks=c(TRUE,FALSE),labels=c("Abnormal","Normal"))
                print(barCompar)})
                
                output$dotPlot <- renderPlot({
                  dotplot <- ggplot(dataSource(), aes(y=Sensor_Value, x=Location, fill=Location))+geom_dotplot(stackratio = .7, binwidth = .01,binaxis = "y", stackdir = "center")+
                    scale_fill_manual(values = c("#FFFFFF","#E95420","#026d62","#b3f442","#b3680a"))
                  print(dotplot)})

                output$line <- renderPlot({
                  data <- dataSource()[dataSource()$Location==Selected(),]
                   p <- ggplot(data, aes(x=Sys_Time, y=Sensor_Value, group=Sensor_ID, colour=Sensor_ID)) + geom_line(size=1)+scale_colour_manual(values=tol21rainbow)
                   print(p)})
                
                output$boxplot <- renderPlot({
                  data <- dataSource()[dataSource()$Location==Selected(),]
                  d <- ggplot(data, aes(y=Sensor_Value, x=Machine_ID, fill=Machine_ID))+geom_boxplot()+scale_colour_manual(values=cbPalette)
                  print(d)})
                
                
          #Operations Dashboard
            #Map Operations    
                # build data with the office locations
                mapData <- data.frame(x=c(-71.06742,-122.33517,-73.93524,-104.99153,-84.38633), 
                                y=c(42.36476,47.60801,40.73061,39.74204,33.75375), id=c("Boston", "Seattle","New York","Denver","Atlanta"))
                
                # create a reactive value that will store the click position
                data_of_click <- reactiveValues(clickedMarker=NULL)
                
                # Leaflet map with markers for each location
                output$map <- renderLeaflet({
                  leaflet() %>% 
                    setView(lng=-98 , lat =40.6, zoom=4) %>%
                    addTiles(options = providerTileOptions(noWrap = TRUE)) %>%
                    addCircleMarkers(data=mapData, ~x , ~y, layerId=~id, popup=~id, radius=8 , color="black",  
                                     fillColor="red", stroke = TRUE, fillOpacity = 0.8)})
                
                # store the click
                observeEvent(input$map_marker_click,{data_of_click$clickedMarker <- input$map_marker_click})
                
                # Make a table depending of the selected office location, machine factor, and sensor factor
                Factor1 <- reactive({input$Factor1})
                
                output$mapTable <- DT::renderDataTable({
                                              my_place <- data_of_click$clickedMarker$id
                                              if(is.null(my_place)){my_place <- "Boston"}
                                              if(my_place=="Boston"){
                                                    data <- dataSource()[dataSource()$Location=="Boston",]
                                                    data <- data.table(data)
                                                    DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                                    Cnt_Abnormal=sum(Reading_Flag)   
                                                    Avg_Reading=round(mean(Sensor_Value), digits=2)
                                                    Min_Reading = min(Sensor_Value)
                                                    Max_Reading = max(Sensor_Value)
                                                    Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                                    Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                                    list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                                         Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                                         Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                                    by=eval(Factor1())], 
                                                    options = list(dom = 't'))
                                              } else if (my_place=="Atlanta"){
                                                    data <- dataSource()[dataSource()$Location=="Atlanta",]
                                                    data <- data.table(data)
                                                    DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                                    Cnt_Abnormal=sum(Reading_Flag)   
                                                    Avg_Reading=round(mean(Sensor_Value), digits=2)
                                                    Min_Reading = min(Sensor_Value)
                                                    Max_Reading = max(Sensor_Value)
                                                    Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                                    Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                                    list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                                         Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                                         Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                                    by= eval(Factor1())], 
                                                    options = list(dom = 't'))
                                              } else if (my_place=="Seattle"){
                                                    data <- dataSource()[dataSource()$Location=="Seattle",]
                                                    data <- data.table(data)
                                                    DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                                    Cnt_Abnormal=sum(Reading_Flag)   
                                                    Avg_Reading=round(mean(Sensor_Value), digits=2)
                                                    Min_Reading = min(Sensor_Value)
                                                    Max_Reading = max(Sensor_Value)
                                                    Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                                    Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                                    list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                                         Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                                         Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                                    by= eval(Factor1())], 
                                                    options = list(dom = 't'))
                                              } else if (my_place=="Denver"){
                                                    data <- dataSource()[dataSource()$Location=="Denver",]
                                                    data <- data.table(data)
                                                    DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                                    Cnt_Abnormal=sum(Reading_Flag)   
                                                    Avg_Reading=round(mean(Sensor_Value), digits=2)
                                                    Min_Reading = min(Sensor_Value)
                                                    Max_Reading = max(Sensor_Value)
                                                    Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                                    Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                                    list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                                         Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                                         Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                                    by= eval(Factor1())], 
                                                    options = list(dom = 't'))
                                              } else if (my_place=="New York"){
                                                    data <- dataSource()[dataSource()$Location=="New York",]
                                                    data <- data.table(data)
                                                    DT::datatable(data[,{Cnt_Readings=length(Sensor_Value)
                                                    Cnt_Abnormal=sum(Reading_Flag)   
                                                    Avg_Reading=round(mean(Sensor_Value), digits=2)
                                                    Min_Reading = min(Sensor_Value)
                                                    Max_Reading = max(Sensor_Value)
                                                    Perc_Abnormal= (round(mean(Reading_Flag), digits = 3))*100
                                                    Perc_Normal=(round(1-(mean(Reading_Flag)), digits = 3))*100
                                                    list(Cnt_Readings=Cnt_Readings,Cnt_Abnormal=Cnt_Abnormal,
                                                         Avg_Reading=Avg_Reading, Min_Reading=Min_Reading, Max_Reading=Max_Reading,
                                                         Perc_Abnormal=Perc_Abnormal,Perc_Normal=Perc_Normal)}, 
                                                    by= eval(Factor1())], 
                                                    options = list(dom = 't'))
                                              } 
                                            })

                outmach <- reactive({
                  ax <- dataSource()[dataSource()$Location==input$loc1,]
                  ax <- unique(ax$Machine_ID)
                  return(ax) })
                
                output$location1 <- renderUI({
                selectInput("loc1", label = h4("Select Location"), 
                            choices = c("Boston" = "Boston", "Seattle" = "Seattle", "New York" = "New York",
                                        "Denver"="Denver","Atlanta" ="Atlanta"), selected = "Boston")})
              
                output$mach <- renderUI({ 
                            selectInput("mach", label = h4("Select Machine"), choices = outmach())})
                            
                output$hist <- renderPlot({
                            data <- dataSource()[(dataSource()$Location==input$loc1),]
                            d <- ggplot(data, aes(Sensor_Value,fill=Sensor_ID))+geom_histogram(binwidth = .1)+scale_fill_manual(values=tol21rainbow)+facet_grid(.~Machine_ID)
                            print(d)})
              
                output$opline <- renderPlot({
                            data<- dataSource()[(dataSource()$Location==input$loc1 & dataSource()$Machine_ID==input$mach),]
                            x <- ggplot(data, aes(x=Sys_Time, y=Sensor_Value, group=Sensor_ID, colour=Sensor_ID))+geom_line(size=1)+scale_colour_manual(values=cbPalette)
                            print(x)})
}
shinyApp(ui = ui, server = server)