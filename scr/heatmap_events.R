# Thu Jun 18 09:47:02 2020 

# Title: Heatmap AllSegments
# Author: Nicolò T.
# Status: complete

# Comments:

# Options ----

rm(list = ls())
options(warn = 1)
options(stringsAsFactors = F,scipen=999)

# Variables ----

argsVal <- commandArgs(trailingOnly = T)

BaseDir <- argsVal[1]
refBonLabel <- argsVal[2]
refBon <- argsVal[2]
setwd(BaseDir)

# comment the lines below ----

# BaseDir <- "/home/nico/intropipeline2/"
# refBonLabel <- "Scc"
# refBon <- "Scc"
# setwd(BaseDir)

# Libraries ----

library(ggplot2)
library(data.table)

# body ----


allChr <- c("chrI", "chrII", "chrIII", "chrIV", "chrV", "chrVI", "chrVII", "chrVIII", 
            "chrIX", "chrX", "chrXI", "chrXII", "chrXIII", "chrXIV", "chrXV", "chrXVI")

allRData <- list.files(paste0(BaseDir,"/int/"),pattern = "blocks.txt")
Events <- data.frame()
for (ind in allRData) {
  print(ind)
  allEv <- fread(paste0("int/",ind),data.table = F)
  allEv <- allEv[allEv$species == "sp" & allEv$mrks >=5,]
  allEv$sample <- sapply(strsplit(ind,"\\."),"[[",1)
  Events <- rbind(Events,allEv)
  rm(allEv)
}

allEv0 <- data.frame()
tabplot <- c()
samples <- c()
tabplot2 <- c()
Events2 <- Events

for (indC in allChr) {
  
  Events <- Events2[Events2$chr == indC,]
  
  if ( nrow(Events) > 0 ) {
    
    samples <- unique(Events$sample)
    
    # tieni solo chr, fisrt , end e Scc ----
    Events <- Events[,c(5,7,8,14)]
    
    Events$Evlength <- Events$end - Events$start
    
    Events$chr <- as.factor(Events$chr)
    
    Events <- Events[order(Events$Evlength,decreasing = T),]
    
    # frammenta e conta----
    Events$counts <- rep(0,times=nrow(Events))
    
    rownames(Events) <- 1:nrow(Events)
    
    allEv0temp <- Events[Events[,"Evlength"] == 0,]
    Events <- Events[!(Events[,"Evlength"] == 0),]
    
    if ( nrow(Events) > 0 ) {
      pointsall <- c()
      
      for (indE in 1:nrow(Events)) {
        pointstemp <-  seq(from = Events[indE,"start"],to = Events[indE,"end"],by = 1)
        pointsall <- c(pointsall,pointstemp)
      }
      
      allEv0 <- rbind(allEv0temp,allEv0)
      
      tab <- as.data.frame(table(pointsall))
      chrs <- rep(indC,times=nrow(tab))
      tab <- as.data.frame(cbind(chrs,tab))
      tab$pointsall <- as.numeric(as.vector(tab$pointsall))
      tabplot <- rbind(tabplot,tab)
      rm(tab,pointsall)
    }
    
  }
  tabplot2 <- rbind(tabplot2,tabplot)
}

rm(tabplot,Events,allEv0,allEv0temp)

tabplot2$chrs <- as.factor(tabplot2$chrs)

centromeric <- read.delim(paste0(BaseDir,"/rep/Ann/Scc.centromere.txt"), header=FALSE)

chrlen <- read.delim(paste0(BaseDir,"/rep/Ann/Scc.chrs.txt"), header=FALSE)

if (nrow(chrlen) == 17) {
  chrlen <- chrlen[-nrow(chrlen),]
}    

xmin <- rep(0,times=nrow(chrlen))
chrlen$xmin <- xmin
colnames(chrlen)[1:2] <- c("chr","xmax")

yminimi <- seq(from=0, to=7.5, by=0.5)
ymassimi <- seq(from=0.25, to=7.75, by=0.5)

chrlen$ymin <- yminimi
chrlen$ymax <- ymassimi

centromeric$ymin <- yminimi
centromeric$ymax <- ymassimi

yminimo <- rep("",times=nrow(tabplot2))
ymassimo <- rep("",times=nrow(tabplot2))

tabplot2$ymin <- yminimo
tabplot2$ymax <- ymassimo

for (ind in 1:length(allChr)) {
  tabplot2[tabplot2[,1] == chrlen[ind,"chr"],"ymin"] <- chrlen[chrlen[,1] == chrlen[ind,"chr"],"ymin"]
  tabplot2[tabplot2[,1] == chrlen[ind,"chr"],"ymax"] <- chrlen[chrlen[,1] == chrlen[ind,"chr"],"ymax"]
}


tabplot2$chrs <- factor(tabplot2$chrs, levels=allChr)
tabplot2 <- tabplot2[order(match(tabplot2[[1]], allChr)), ]
tabplot2$ymax <- as.numeric(tabplot2$ymax)
tabplot2$ymin <- as.numeric(tabplot2$ymin)


tabplot3 <- data.frame()
for (indC in as.character(unique(tabplot2$chrs)) ) {
  temptab <- tabplot2[tabplot2[,1] == indC,]
  conte <- rle(temptab$Freq)[["lengths"]]
  print(indC)
  start <- 0
  end <- 0
  taBB <- data.frame()
  for ( ind in 1:length(conte) ) {
    print(ind)
    if ( ind == 1 ) { 
      inizio <- start + 1
      fine <- end + conte[ind]
    }
    
    tab1 <- temptab[inizio:fine,]
    chr <- unique(tab1$chrs)
    freq <- unique(tab1$Freq)
    
    if ( length(unique( diff(tab1$pointsall) ) ) != 1 & length(diff(tab1$pointsall)) != 0 ) {
      
      tab2 <- unname(tapply(tab1$pointsall, cumsum(c(1, diff(tab1$pointsall)) != 1), range))
      
      tab3 <- data.frame()
      for (ind2 in 1:length(tab2)) {
        tab4 <-  data.frame(tab2[[ind2]][1],tab2[[ind2]][2])
        tab3 <- rbind(tab3,tab4)
      }
      
      tab3$chr <- chr
      tab3$freq <- freq
      colnames(tab3)[1:2] <- c("start","end")
      
      if (nrow(taBB) != 0) {
        colnames(taBB)<- c("start","end","chr","freq")
      }
      
      taBB <- rbind(taBB,tab3)
    } else {
      riga <- c(min(tab1$pointsall),max(tab1$pointsall),as.character(tab1[1,1]),unique(tab1$Freq))
      taBB <- rbind(taBB,riga)
    }
    
    if (ind != length(conte)) {
      inizio <- fine + 1
      fine <- fine + (conte[ind+1]) 
    }
  }
  colnames(taBB)<- c("start","end","chr","freq")
  tabplot3 <- rbind(tabplot3,taBB)
}

tabplot3[,1] <- as.numeric(tabplot3[,1])
tabplot3[,2] <- as.numeric(tabplot3[,2])
tabplot3[,4] <- as.numeric(tabplot3[,4])

tabplot3$length <- tabplot3$end -  tabplot3$start
tabplot3 <- tabplot3[order(tabplot3$length,decreasing = T),]

tabplot3$ymin <- rep("",times=nrow(tabplot3))
tabplot3$ymax <- rep("",times=nrow(tabplot3))

for (indC in allChr) {
  tabplot3[tabplot3[,3] == indC,"ymin"] <- chrlen[chrlen[,1] == indC,"ymin"]
  tabplot3[tabplot3[,3] == indC,"ymax"] <- chrlen[chrlen[,1] == indC,"ymax"]
}

# Plot part ----

# Rescale ----

tabplot3[,1] <- tabplot3[,1] / 1000
tabplot3[,2] <- tabplot3[,2] / 1000
centromeric[,c(1,2)] <- centromeric[,c(1,2)] / 1000
chrlen[,c(2,3)] <- chrlen[,c(2,3)] /1000

tabplot3[,6] <- as.numeric(tabplot3[,6])
tabplot3[,7] <- as.numeric(tabplot3[,7])

pHeatRainbow <- ggplot(tabplot3) + 
  geom_rect(tabplot3,mapping = aes(xmin=start, xmax=end, ymin=ymin,ymax=ymax,fill=freq)) +
  geom_rect(chrlen, mapping = aes(xmin=0, xmax=xmax, ymin=ymin,ymax=ymax),fill="grey99",color="black", linewidth=.1,alpha=0.000001) +
  scale_fill_distiller( type = "seq", palette = 8,direction = 1) +
  geom_point(centromeric,mapping = aes(x =((as.numeric(V1) + as.numeric(V2))/2), y=((as.numeric(ymin) + as.numeric(ymax))/2)),color="black",fill="black") +
  annotate(geom="text", x=as.numeric(-0.05), y=((as.numeric(yminimi) + as.numeric(ymassimi))/2), label=allChr ,color="black",hjust=1.5,size=3) +
  scale_x_continuous(name="Genomic Position (Kb)") +
  theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    panel.border = element_blank(), 
    panel.background = element_blank(),
    axis.title.y=element_blank(),
    axis.text.y=element_blank(),
    axis.ticks.y=element_blank(), 
  ) + 
  labs(fill = "samples fraction",title = "Heatmap")

pPath <- file.path(paste0(BaseDir,"/int/allintrogressions.heatmap.pdf"))
pdf(file = pPath, width = 16, height = 10)
print(pHeatRainbow)
dev.off()

fwrite(tabplot2,paste0(BaseDir,"/int/allintrogressions.heatmap.txt"),append = F,quote = F,sep = "\t",row.names = F,col.names = T)