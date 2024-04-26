# UVA STAT 4220 - Applied Analytics for Business
# Final Group Project: Analyzing Facebook Advertising Data
# Collection of Core Code Snippets
# BC HWANG (bh2xc)


#### LOAD PACKAGES
library(tidyverse)
library(tidymodels)
library(modelr)
library(randomForest)
library(Metrics)
library(GGally)
library(stats)
library(car)
library(yardstick)
library(viridis)
library(gridExtra)


#### IMPORT DATA
mydata <- read_csv("~/RStudio/STAT 4220 - Biz Analytics/Data/conversion.csv")


#### DATA PREPARATION
# drop columns containing redundant advertisement identification data
mydata$fb_campaign_id <- NULL
mydata$interest <- NULL

# check for NA values in data frame - FALSE for all variables
apply(mydata, 2, function(x) any(is.na(x)))

# rename columns and set to lowercase 
names(mydata) <- tolower(names(mydata))
names(mydata)[names(mydata) == "gender"] <- "male"
names(mydata)[names(mydata) == "xyz_campaign_id"] <- "campaign"
names(mydata)[names(mydata) == "total_conversion"] <- "total_conv"
names(mydata)[names(mydata) == "approved_conversion"] <- "app_conv"

# recode biological sex variable
mydata$male[mydata$male == 'M'] <- 1
mydata$male[mydata$male == 'F'] <- 0
mydata$male <- as.integer(mydata$male)

# recode age variable
mydata$age[mydata$age == '30-34'] <- 32
mydata$age[mydata$age == '35-39'] <- 37
mydata$age[mydata$age == '40-44'] <- 42
mydata$age[mydata$age == '45-49'] <- 47
mydata$age <- as.integer(mydata$age)

# recode campaign id variable
mydata$campaign[mydata$campaign == 916] <- "campaign_1"
mydata$campaign[mydata$campaign == 936] <- "campaign_2"
mydata$campaign[mydata$campaign == 1178] <- "campaign_3"
mydata$campaign <- as.factor(mydata$campaign)

# create 2 dummy variables for the 3 levels of the campaign id variable
mydata <- mydata %>%
  mutate(is_c1 = ifelse(campaign=="campaign_1",1,0),
         is_c2 = ifelse(campaign=="campaign_2",1,0))


#### DESCRIPTIVE ANALYTICS
# Figure 1: per-campaign advertisement counts
mydata$campaign <- recode(mydata$campaign,
                          "campaign_1" = "1",
                          "campaign_2" = "2",
                          "campaign_3" = "3")
mydata %>%
  count(campaign) %>%
  kable(col.names = c("Campaign","Count"),
        caption="Advertisement Counts Per Campaign")
mydata$campaign <- recode(mydata$campaign,
                          "1" = "campaign_1",
                          "2" = "campaign_2",
                          "3" = "campaign_3")

# Figure 2: box plots of selected campaign characteristics
mydata$campaign <- recode(mydata$campaign,
                          "campaign_1" = "1",
                          "campaign_2" = "2",
                          "campaign_3" = "3")
p1 <- ggplot(mydata, aes(campaign, sqrt(clicks), fill=campaign)) + 
  geom_boxplot(outlier.shape=1, alpha=0.5) + 
  scale_fill_viridis(discrete="true", alpha=0.9) +
  labs(x="Campaign",
       y="Clicks",
       title="Clicks",
       subtitle="Square Root Transformation Applied") +
  theme(legend.position="none",
        plot.title=element_text(size=14),
        plot.subtitle=element_text(size=8)) +
  coord_flip()
p2 <- ggplot(mydata, aes(campaign, sqrt(impressions), fill=campaign)) + 
  geom_boxplot(outlier.shape=1, alpha=0.5) + 
  scale_fill_viridis(discrete="true", alpha=0.9) +
  labs(x="",
       y="Impressions",
       title="Impressions",
       subtitle="Square Root Transformation Applied") +
  theme(legend.position="none",
        plot.title=element_text(size=14),
        plot.subtitle=element_text(size=8)) +
  coord_flip()
p3 <- ggplot(mydata, aes(campaign, sqrt(spent), fill=campaign)) + 
  geom_boxplot(outlier.shape=1, alpha=0.5) + 
  scale_fill_viridis(discrete="true", alpha=0.9) +
  labs(x="Campaign",
       y="Spending",
       title="Per-Ad Spending",
       subtitle="Square Root Transformation Applied") +
  theme(legend.position="none",
        plot.title=element_text(size=14),
        plot.subtitle=element_text(size=8)) +
  coord_flip()
p4 <- ggplot(mydata, aes(campaign, sqrt(app_conv), fill=campaign)) + 
  geom_boxplot(outlier.shape=1, alpha=0.5) + 
  scale_fill_viridis(discrete="true", alpha=0.9) +
  labs(x="",
       y="Approved Conversion",
       title="Approved Conversion",
       subtitle="Square Root Transformation Applied") +
  theme(legend.position="none",
        plot.title=element_text(size=14),
        plot.subtitle=element_text(size=8)) +
  coord_flip()
mydata$campaign <- recode(mydata$campaign,
                          "1" = "campaign_1",
                          "2" = "campaign_2",
                          "3" = "campaign_3")
grid.arrange(p1,p2,p3,p4, ncol=2)

# Figure 3: correlation plots of quantitative predictors
pairs(mydata[5:9], 
      labels = c("Impressions","Clicks","Spending",
                 "Total Conversion","Approved Conversion"),
      lower.panel = NULL)

# Figure 4: correlation matrix of quantitative predictors
correlation = as.data.frame(row = c("Impressions","Clicks","Spending",
                                    "Total Conversion","Approved Conversion"),
                            round(cor(mydata[5:9]), 3))
names(correlation) <- c("Impressions","Clicks","Spending",
                        "Total Conversion","Approved Conversion")
kable(correlation, 
      caption="Correlation Matrix of Quantitative Predictors")

# Figure 5: bar plots of demographic data distributions
mydata$male <- recode(mydata$male, 
                      "0"="Female", 
                      "1"="Male")
mydata$age <- recode(mydata$age,
                     "32" = "30-34",
                     "37" = "35-39",
                     "42" = "40-44",
                     "47" = "45-49")
ggplot(mydata, aes(x=age, fill=as.factor(age))) + 
  geom_bar(show.legend = FALSE) +
  geom_text(stat='count', aes(label=..count..), vjust=-0.5) +
  facet_wrap(~male) +
  scale_fill_viridis(discrete="true", alpha=0.9) +
  labs(x = "Age Brackets",
       y = "Count",
       title = "Distribution of Audiences by Age and Biological Sex") +
  lims(y=c(0,250))
mydata$male <- recode(mydata$male, 
                      "Female" = 0, 
                      "Male" = 1)
mydata$age <- recode(mydata$age,
                     "30-34" = 32,
                     "35-39" = 37,
                     "40-44" = 42,
                     "45-49" = 47)


#### PREDICTIVE ANALYTICS
# set seed for reproducible data splitting
set.seed(4220)

# define training (60%), validation (20%), and testing (20%) subsets
fb.div <- mydata %>%
  initial_split(prop = 0.6, strata = campaign)
fb.div1 <- fb.div %>%
  testing() %>%
  initial_split(prop = 0.5, strata = campaign)
fb.train <- training(fb.div)
fb.val <- training(fb.div1)
fb.test <- testing(fb.div1)

# random forest models - initial
rf.app <- randomForest(app_conv ~ age + male + impressions + 
                         clicks + spent + is_c1 + is_c2, 
                       data = fb.train, mtry = 2, importance = TRUE)
rf.tot <- randomForest(total_conv ~ age + male + impressions + 
                         clicks + spent + is_c1 + is_c2,
                       data = fb.train, mtry = 2, importance = TRUE)

# random forest models - pruned
rf.app.1 <- randomForest(app_conv ~ age + impressions + clicks + spent, 
                         data = fb.train, mtry = 2, importance = TRUE)
rf.tot.1 <- randomForest(total_conv ~ age + impressions + clicks + spent, 
                         data = fb.train, mtry = 2, importance = TRUE)

# random forest models - assessment w/ training subset
mods.tr <- c("Initial - Approved Conversion",
             "Reduced - Approved Conversion",
             "Initial - Total Conversion",
             "Reduced - Total Conversion")
rmse.tr <- c(sqrt(rf.app$mse[length(rf.app$mse)]),
             sqrt(rf.app.1$mse[length(rf.app.1$mse)]),
             sqrt(rf.tot$mse[length(rf.tot$mse)]),
             sqrt(rf.tot.1$mse[length(rf.tot.1$mse)]))
sum.tr <- data.frame(mods.tr, rmse.tr)

# random forest models - assessment w/ validation subset
pred.init.app <- predict(rf.app, fb.val)
pred.red.app <- predict(rf.app.1, fb.val)
pred.init.tot <- predict(rf.tot, fb.val)
pred.red.tot <- predict(rf.tot.1, fb.val)
mods.v <- c("Initial - Approved Conversion",
            "Reduced - Approved Conversion",
            "Initial - Total Conversion",
            "Reduced - Total Conversion")
rmse.v <- c(rmse(fb.val$app_conv, pred.init.app),
            rmse(fb.val$app_conv, pred.red.app),
            rmse(fb.val$total_conv, pred.init.tot),
            rmse(fb.val$total_conv, pred.red.tot))
sum.v <- data.frame(mods.v, rmse.v)

# random forest models - assessment w/ testing subset
pred.test.app <- predict(rf.app, fb.test)
pred.test.tot <- predict(rf.tot, fb.test)
rmse(fb.test$app_conv, pred.test.app)
rmse(fb.test$total_conv, pred.test.tot)
mods.t <- c("Initial - Approved Conversion",
            "Initial - Total Conversion")
rmse.t <- c(rmse(fb.test$app_conv, pred.test.app),
            rmse(fb.test$total_conv, pred.test.tot))
sum.t <- data.frame(mods.t, rmse.t)

# random forest models - variable importance
varnam <- c("Impressions", "Spent", "Clicks", "Age", 
            "Campaign 2", "Campaign 1", "Male")
app.imp <- c(21.667, 15.536, 15.235, 13.526, 9.747, -0.153, 4.458)
tot.imp <- c(23.868, 17.291, 15.348, 18.842, 12.147, 5.464, 2.760)
sum.imp <- data.frame(varnam, app.imp, tot.imp)

# linear regression models - finalized
LinReg.mod1 = lm(total_conv ~ age + impressions + clicks + spent + is_c1 + is_c2, 
                 data = fb.train)
LinReg.mod.a3 <- lm(app_conv ~ impressions + spent + is_c1 + is_c2, 
                    data = fb.train)

# linear regression models - assessment results
mods.lr <- c("Initial - Approved Conversion",
             "Final - Approved Conversion",
             "Initial - Total Conversion",
             "Final - Total Conversion")
mods.lr1 <- c("Initial - Approved Conversion",
              "Initial - Total Conversion")
rmse.lr.tr <- c(3.63, 3.87, 2.14, 2.21)
rmse.lr.v <- c(4.60, 5.39, 2.14, 2.21)
rmse.lr.te <- c(4.32, 2.86)

sum.lr.tr <- data.frame(mods.lr, rmse.lr.tr)
sum.lr.v <- data.frame(mods.lr, rmse.lr.v)
sum.lr.te <- data.frame(mods.lr1, rmse.lr.te)

Final_Total = coef(summary(LinReg.mod1))

row.names(Final_Total) <- c("(Intercept)", "Age", "Impressions", "Clicks", 
                            "Spent", "Campaign 1", "Campaign 2")

Final_TotalR = data.frame("R2" = 0.7556, "Adj. R2" = 0.7535, "P-Value" = "< 2.2e-16")

Final_Approved = coef(summary(LinReg.mod.a3))

row.names(Final_Approved) <- c("(Intercept)", "Impressions", "Spent", 
                               "Campaign 1", "Campaign 2")

Final_ApprovedR = data.frame("R2" = 0.6098, "Adj. R2" = 0.6075, "P-Value" = "< 2.2e-16")
