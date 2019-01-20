library(chron)
library(reshape)
library(Hmisc)

setwd("~")

# find average accessibility for a period of the day

# home location data
dadata <- read.csv("dauid.csv")

# days to compute this for
days <- c("Tuesday.csv","Thursday.csv") #etc.

for (day in days) {

  # input Tmin data
  df <- read.csv(paste("Tmin_day/walk/",day,sep = ""))

  rownames(df) <- df$dauid

  # start and end times to average over
  c1 <- which( colnames(df)=="X10.0" )
  c2 <- which( colnames(df)=="X14.0" )

  # select justs the columns between c1 and c2
  dfa <- df[c1:c2]

  dfa[dfa > 60] <- 60

  # compute mean over this period
  dfm <- as.data.frame(rowMeans(dfa, na.rm = FALSE, dims = 1))

  colnames(dfm) <- c(day)

  dfo <- merge(dadata,dfm,by.x="dauid",by.y=0)

}

# output the data
out <- "out_file_name.csv"
write.csv(x = dfo, file = out)
