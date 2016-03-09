


#The purpose of this script is to combine all the identifiers
# from the cells and explants inventories into one place so the
# microarray results can be more easily connected to  corresponding RNA 
# concentrations and qPCR results.



#reading in data about the explant RNA and mergeing 
#so I have data with the microarray sample# AND
#the concentrations in the same spreadsheet

library(dplyr)
library(stringr)

log <- read.csv("Herpes explant RNA log.csv")

key <- read.csv("Herpes explant microarray key.csv")

names(key)[3]<-"Sample.ID"

complete <- merge(log,key,by="Sample.ID")

#this includes data for all samples
write.table(complete, "complete explant RNA log.txt",row.names=FALSE,
            sep = "\t")



#read in the new nanodrop data that I generated 22Feb16 for the
#samples that will be used for qPCR
nanodrop<-read.table("explant and cells RNA nanodrop 22Feb16.txt",
                     header=TRUE,sep="\t")


#edit nanodrop to get just the explant data and fix errors
nanodropExplant<-nanodrop %>%
  mutate(Sample.ID=str_replace(Sample.ID,"a","A"))%>%
  select(Sample.ID, ng.ul)%>%
  slice(2:43)

#edit the col names so they merge well with the old data
names(nanodropExplant)[1]<-"ID"
names(nanodropExplant)[2]<-"newNanodrop"

#merge with original data
explant_RNA_for_qPCR<-merge(nanodropExplant,complete, by = "ID")

#write out data to be added to excel file. This ONLY has data for 
#the samples that were ok to use for qPCR

write.table(explant_RNA_for_qPCR, "explant_RNA_for_qPCR.txt",row.names=FALSE,
            sep = "\t")

### CELLS DATA

#now reading in the cells phenoData that I used for MA
#analysis and the Herpes cells RNA log to have both concentrations
#AND microarray sample ID in the same spreadsheet

cellsPhenoData<-read.table("../Herpes-Project-1/vaginalCellMicroarrayPhenoData.txt",
                           header=TRUE, row.names=NULL)

cellsRNAlog<-read.csv("Herpes cells RNA log.csv")


names(cellsRNAlog)[c(3,5)]<-c("TissueID","Treatment")


cellsRNAlog$Treatment<-str_replace(cellsRNAlog$Treatment, "186", "V186")

cellsRNAlog$Treatment<-str_replace(cellsRNAlog$Treatment, "mock", "Mock")


#make a column that concatentates TissueID, Time and Treatment in both data frames

cellsRNAlog<-cellsRNAlog %>%
  mutate(ID = paste(cellsRNAlog$TissueID,cellsRNAlog$Time,cellsRNAlog$Treatment, sep=""))


cellsPhenoData<-cellsPhenoData %>%
  mutate(ID = paste(cellsPhenoData$TissueID,cellsPhenoData$Time,cellsPhenoData$Treatment, sep=""))


CellsComplete<-merge(cellsPhenoData,cellsRNAlog, by = "ID")


#CHECKING
#check that things are lined up:

#this is False I think because one is a factor and the other is a character
identical(CellsComplete$Treatment.x, CellsComplete$Treatment.y)
#but this is true so it's ok
CellsComplete$Treatment.x==CellsComplete$Treatment.y

identical(CellsComplete$Time.x, CellsComplete$Time.y)
identical(CellsComplete$TissueID.x, CellsComplete$TissueID.y)
### END CHECKING


CellsComplete<-select(CellsComplete, sampleNames,Row,Col,TissueID.x, Treatment.x,Time.x, ng.ul)
colnames(CellsComplete)<-c("SampleNames on MA","Row","Col","TissueID","Treatment","Time","ng/ul")


#make a column for the tube labels
CellsComplete<-CellsComplete %>%
  mutate(TubeLabel = paste(TissueID, Time, sep="."))%>%
  mutate(TubeLabel= paste(TubeLabel, Treatment, sep=" "))%>%
  mutate(TubeLabel = str_replace(TubeLabel, "SD90","SD"))%>%
  mutate(TubeLabel = str_replace(TubeLabel, "V186","186"))

write.table(CellsComplete, file="complete vaginal cells RNA log.txt", sep="\t",
            row.names=FALSE)

#Now add the new nanodrop data that I generated just for the samples that
#we are doing qPCR on (all except HVE3 because we couldnt find those)
#Edit the nanodrop file to get just the CELLS data
nanodropCells<-nanodrop %>%
  select(Sample.ID, ng.ul)%>%
  slice(44:61)

#rename the columns so they merge well with the original data
names(nanodropCells)[1]<-"TubeLabel"
names(nanodropCells)[2]<-"newNanodrop"

#merge into the rest of the cells data
Cells_RNA_for_qPCR<-merge(CellsComplete, nanodropCells, by = "TubeLabel")

#write out data to be added to excel file and given to Erik. This ONLY
#has data for the samples that we are running qPCR on.

write.table(Cells_RNA_for_qPCR, file="Cells_RNA_for_qPCR.txt", sep="\t",
            row.names=FALSE)

