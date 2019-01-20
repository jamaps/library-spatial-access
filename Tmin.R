library(chron)
library(reshape)

# working directory
setwd("~")

# min visit time in seconds
min_visit_time <- 30 * 60

# location data for evaluation - in this case centroids of census zones in Canada
dadata <- read.csv("dauid.csv")

# open up the travel time matrix
fname <- "m_drive/m_20_10_0.csv"
dft <- read.csv(fname,row.names = 1)
dft <- dft[ , order(names(dft))]

# for each day of the week
days <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
for (day in days) {

  # load in the hours of the libraries
  hours <- read.csv("libs_coords.csv",colClasses=c(rep("character",10)),na.strings=c(""," ","Closed","NA"))

  # coding their opening and closing to variables
  day_open <- paste(day,"O", sep = "")
  day_close <- paste(day,"C", sep = "")
  hsub <- hours[,c("ID",day_open,day_close)]
  hsub$tau_o <- as.POSIXct(hsub[,2],format="%H:%M")
  hsub$tau_c <- as.POSIXct(hsub[,3],format="%H:%M")
  midnight <- as.POSIXct("00:00",format="%H:%M")
  hsub$tau_c <- as.numeric(hsub$tau_c - midnight) * 60 * 60
  hsub$tau_o <- as.numeric(hsub$tau_o - midnight) * 60 * 60
  hsub <- hsub[,c("ID","tau_o","tau_c")]

  dadata <- read.csv("dauid.csv")

  # starting at 8am
  h <- 8

  # lopping each hour until 9pm
  while (h < 21) {

    # looping over each minute in the hour
    m <- 0

    while (m < 60) {

      # compute minimum dpearture times

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

      # merge data to the output
      dadata <- merge(dadata,out,by.x="dauid",by.y="dauid")

      m <- m + 5

      print(paste(h,m))

      }

  h <- h + 1

  }

  # saving the output
  write.csv(x = dadata,file = paste("Tmin_day/drive/",day,".csv",sep=""))

}
