## Final project for R Course 3: Getting and cleaning data
## Author: Serban Tanasa
## Date created: 2014.08.24
## Date last modified: 2014.08.24

## The task is to process biometric data from sensors placed 
## on 30 subjects, engaged in 6 labeled activities.
## 561 data vectors were stored. 
## The goals are to 
## 1) Merge the training and test data
## 2) extract mean and std data from the file,
## 3) use the activity labels provided to enrich the data
## 4) Create human-friendly labels for the data columns
## 5) Save average values for each activity and each subject 
## For clarity, create a
## a) CodeBook.md -- listing all variables in a useful way.
## b) README.md -- a quick listing of how the script works. 

#See if data.table can be loaded, if not attempt to install and load. 
if(!library(data.table, logical.return=TRUE)) 
{install.packages("data.table")
 library(data.table)} 

if(!library(reshape2, logical.return=TRUE)) 
{install.packages("reshape2")
 library(reshape2)} 

#setwd("./")  #setwd to appropriate directory if needed.

#Create a temp file to store the downloaded zip. Download the archive. 
archiveinwd <- file.exists("getdata-projectfiles-UCI HAR Dataset.zip")

if(archiveinwd) {
     #set path to read pre-downloaded archive
     tmp <- "getdata-projectfiles-UCI HAR Dataset.zip" 
} else { #if file not found in working dir, download to temp file
tmp <- tempfile()
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", tmp,
              mode="wb")
}

# No need to bother unzipping the file by hand, but instead
# use the unz() function to get the bits I need from inside the archive.

#Examine the readme file
readme <- readLines(unz(tmp, "UCI HAR Dataset/README.txt"))
grep("The dataset includes the following files:", readme)

#@ Extract relevant feature names from the features list file.
features <- read.table(unz(tmp, "UCI HAR Dataset/features.txt"), stringsAsFactors=F)
dim(features)
features.subset <- features[grep("mean\\(\\)-.$|-mean\\(\\)$|std\\(\\)-.$|-std\\(\\)$",features$V2, value=F),]
dim(features.subset)

#Extract activity labels w/ names and numeric codes. 
activitylabels <- read.table(unz(tmp, "UCI HAR Dataset/activity_labels.txt"))

Get the actual data

train.data1 <- read.table(unz(tmp, "UCI HAR Dataset/train/X_train.txt"))
train.data2 <- read.table(unz(tmp, "UCI HAR Dataset/train/subject_train.txt"))
train.data3 <- read.table(unz(tmp, "UCI HAR Dataset/train/y_train.txt"))

test.data1 <- read.table(unz(tmp, "UCI HAR Dataset/test/X_test.txt"))
test.data2 <- read.table(unz(tmp, "UCI HAR Dataset/test/subject_test.txt"))
test.data3 <- read.table(unz(tmp, "UCI HAR Dataset/test/y_test.txt"))


dim(train.data1)
dim(train.data2)
dim(train.data3)
table(train.data2) ###--- Individual subject labels
table(train.data3) ###--- Activity labels

#train.data2
#1   3   5   6   7   8  11  14  15  16  17  19  21  22  23  25  26  27  28  29  30 
#347 341 302 325 308 281 316 323 328 366 368 360 408 321 372 409 392 376 382 344 383 

dim(test.data1)
dim(test.data2) 
dim(test.data3)
table(test.data2) ###--- Individual subject labels
table(test.data3) ###--- Activity labels

#test.data2
#2   4   9  10  12  13  18  20  24 
#302 317 288 294 320 327 364 354 381 

#So some subjects are only in test, and some subjects only in train.
# This suggests that rbinding first might be a good idea. 

## We rbind the data, placing test data first (no particular reason,
## just to make sure we're being consistent). 
data1 <- rbind(test.data1, train.data1)
data2 <- rbind(test.data2, train.data2)
data3 <- rbind(test.data3, train.data3)

dim(data1)
dim(data2)
dim(data3)

names(data1)
table(data2)
table(data3)

# Create a factor version of the person data
data2.1 <- factor(data2$V1, levels=1:30, labels=paste0("Subject_",1:30))

# create a factor version of the activity data (data3)
data3.1 <- factor(data3$V1, levels=activitylabels$V1, labels=activitylabels$V2)


# Subset the sensor data to get only the mean and std values using the grep
# subsetting we performed earlier.

data1.1 <- data1[,features.subset$V1]
names(data1.1) <- features.subset$V2

head(data1.1)
dim(data1.1)

#Join everything together and name first two columns appropriately
data_final <- cbind(data2.1, data3.1, data1.1)
names(data_final)[1] <- "SubjectID"
names(data_final)[2] <- "Activity"

#Melt to obtain a tidy long format, then aggregate by Subject, Activity and Measurement,
# taking the mean for each measurement/Subject/Activity
data_melt <- melt(data_final, id.vars=c("SubjectID", "Activity"))
tidy_result <- data_melt[,mean(value), by=list(SubjectID, Activity, variable)]

#Name variables, and order using data.table commands. 
setnames(tidy_result, c("SubjectID","Activity","Measure","Average"))
setkey(tidy_result, SubjectID, Activity)            

write.table(tidy_result, "tidyresult.txt", row.name=F)
#write.table(features.subset$V2, "CodeBook.md", row.name=F)
