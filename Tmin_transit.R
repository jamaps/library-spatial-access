library(chron)
library(reshape)
library(compare)

setwd("~")

# set the minimum visit time
min_visit_time <- 30 * 60

# location data for evaluation - in this case centroids of census zones in Canada
dadata <- read.csv("dauid.csv")

# open up the csv matrix for walking
walk <- "m_walk/m_20_10_0.csv"
dfw <- read.csv(walk,row.names = 1)
dfw <- dfw[ , order(names(dfw))]

days <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")

# loop over each day of the week
for (day in days) {

  # name of transit matrix folder to use
  print(day)
  if (day == "Sunday") {
    fname <- "m_transit_sunday"
    dd <- "18"
    mh <- 17
  }
  else if (day == "Saturday") {
    fname <- "m_transit_saturday"
    dd <- "17"
    mh <- 18

  }
  else {
    fname <- "m_transit_weekday"
    dd <- "15"
    mh <- 21
  }
  print(fname)

  # reading in the hours for the set day
  hours <- read.csv("libs_coords.csv",colClasses=c(rep("character",10)),na.strings=c(""," ","Closed","NA"))

  day_open <- paste(day,"O", sep = "")
  day_close <- paste(day,"C", sep = "")

  hsub <- hours[,c("ID",day_open,day_close)]

  hsub$tau_o <- as.POSIXct(hsub[,2],format="%H:%M") # adding values is in seconds !
  hsub$tau_c <- as.POSIXct(hsub[,3],format="%H:%M") # adding values is in seconds !
  midnight <- as.POSIXct("00:00",format="%H:%M")
  hsub$tau_c <- as.numeric(hsub$tau_c - midnight) * 60 * 60
  hsub$tau_o <- as.numeric(hsub$tau_o - midnight) * 60 * 60

  hsub <- hsub[,c("ID","tau_o","tau_c")]

  dadata <- read.csv("dauid.csv")

  h <- 8

  while (h < mh) {

    m <- 0


    while (m < 60) {

      m_name <- paste(fname,"/m_",dd,"_",toString(h),"_",toString(m),".csv", sep="")

      dft <- read.csv(m_name,row.names = 1)
      dft <- dft[ , order(names(dft))]

      dft <- merge(dft,dfw,by = 0)
      dft <- transform(dft, A = pmin(A.x, A.y))
      dft <- transform(dft, CA = pmin(CA.x, CA.y))
      dft <- transform(dft, CO = pmin(CO.x, CO.y))
      dft <- transform(dft, GB = pmin(GB.x, GB.y))
      dft <- transform(dft, GE = pmin(GE.x, GE.y))
      dft <- transform(dft, PW = pmin(PW.x, PW.y))
      dft <- transform(dft, RP = pmin(RP.x, RP.y))
      dft <- transform(dft, SV = pmin(SV.x, SV.y))
      dft <- transform(dft, SU = pmin(SU.x, SU.y))
      rownames(dft) <- dft[,1]
      dft <- dft[-(1:19)]


      tau_dept <- h * 60 * 60 + m * 60
      df <- dft + tau_dept # arrival time
      dfm <- melt(as.matrix(df))
      colnames(dfm) <- c("dauid","libid","value")
      dfm <- merge(dfm,hsub,by.x="libid",by.y="ID",all = TRUE)
      dfm$vtime <- (dfm$value + min_visit_time <= dfm$tau_c) # true if can get there and visit before close
      dfm$bopen <- (dfm$value >= dfm$tau_o) # true if get there and already open


      dfm$Ti <- ifelse(dfm$vtime, ifelse(dfm$bopen,dfm$value - tau_dept,dfm$tau_o - tau_dept), NA)
      dfm$Ti[is.na(dfm$Ti)] <- 42000

      out <- aggregate(Ti/60 ~ dauid, data = dfm, FUN = min)
      dept_string <- paste(h, m)
      colnames(out) <- c("dauid",dept_string)

      dadata <- merge(dadata,out,by.x="dauid",by.y="dauid")

      m <- m + 5

      print(paste(h,m))


    }

    h <- h + 1

  }


  write.csv(x = dadata,file = paste("Tmin_day/transit/",day,".csv",sep=""))

}
