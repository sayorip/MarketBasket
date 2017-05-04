#Implementing Market Basket Analysis using Apriori Algorithm
library("aws.s3")

Sys.setenv("AWS_ACCESS_KEY_ID" = "AKIAIEMBA54GTEFBRXHQ",
           "AWS_SECRET_ACCESS_KEY" = "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",
           "AWS_DEFAULT_REGION" = "us-west-1"
          )

#read transactions
df_groceries <- read.csv(url("https://s3-us-west-1.amazonaws.com/rmrketbasket/coupons.csv"))
#df_groceries <- read.csv("coupons_dataset.csv")

str(df_groceries)

df_sorted <- df_groceries[order(df_groceries$Member_number),]


#convert member number to numeric
df_sorted$Member_number <- as.numeric(df_sorted$Member_number)


#convert item description to categorical format

df_sorted$itemDescription <- as.factor(df_sorted$itemDescription)

str(df_sorted)

#convert dataframe to transaction format using ddply; 

if(sessionInfo()['basePkgs']=="dplyr" | sessionInfo()['otherPkgs']=="dplyr"){
  detach(package:dplyr, unload=TRUE)
}

#group all the items that were bought together; by the same customer on the same date
library(plyr)
df_itemList <- ddply(df_groceries, c("Member_number","Date"), function(df1)paste(df1$itemDescription,collapse = ","))

#remove member number and date
df_itemList$Member_number <- NULL
df_itemList$Date <- NULL

colnames(df_itemList) <- c("itemList")

#write to csv format
#write.csv(df_itemList,"https://s3-us-west-1.amazonaws.com/rmrketbasket/groceries.csv", quote = FALSE, row.names = TRUE)

zz <- rawConnection(raw(0), "r+")
write.csv(df_itemList, zz)

# upload the object to S3
aws.s3::put_object(file = rawConnectionValue(zz),
                   bucket = "rmrketbasket", object = "groceries.csv")

# close the connection
close(zz)

#-------------------- association rule mining algorithm : apriori -------------------------#

#load package required
library(arules)

#convert csv file to basket format
txn = read.transactions(file="ItemList.csv", rm.duplicates= FALSE, format="basket",sep=",",cols=1);

#remove quotes from transactions
txn@itemInfo$labels <- gsub("\"","",txn@itemInfo$labels)


#run apriori algorithm
basket_rules <- apriori(txn,parameter = list(minlen=2,sup = 0.00005, conf = 0.001, target="rules"))
#basket_rules <- apriori(txn,parameter = list(minlen=2,sup = 0.00001, conf = 0.01, target="rules"),appearance = list(lhs = "CLEMENTINES")))

#check if tm is attched; if yes then detach
if(sessionInfo()['basePkgs']=="tm" | sessionInfo()['otherPkgs']=="tm"){
  detach(package:sentiment, unload=TRUE)
  detach(package:tm, unload=TRUE)
}


#view rules
inspect(basket_rules)

#convert to datframe and view; optional
df_basket <- as(basket_rules,"data.frame")
df_basket$confidence <- df_basket$confidence * 100
df_basket$support <- df_basket$support * nrow(df)

#write.csv(df_basket,"Rules_.csv",row.names = FALSE)

zz <- rawConnection(raw(0), "r+")
write.csv(df_basket, zz)

# upload the object to S3
aws.s3::put_object(file = rawConnectionValue(zz),
                  bucket = "rmrketbasket", object = "Rules_.csv")

# close the connection
close(zz)

#plot the rules
dev.off()

library(arulesViz)
plot(basket_rules)

set.seed(8000)
plot(basket_rules, method = "grouped", control = list(k = 5))

plot(basket_rules[1:10,], method="graph", control=list(type="items"))

plot(basket_rules[1:10,], method="paracoord",  control=list(alpha=.5, reorder=TRUE))

itemFrequencyPlot(txn, topN = 5)

plot(basket_rules[1:10,],measure=c("support","lift"),shading="confidence",interactive=T)

