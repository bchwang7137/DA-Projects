# UVA ECON 4160 - Health Economics
# Term Paper: Poverty and Low Birthweight
# Data Prep/Analysis Script
# BC HWANG (bh2xc)


# load required packages
library(tidyverse)
library(modelr)
library(tidymodels)
library(car)


# read in data
mydata <- read_csv("nlsy79_cya_1.csv")


# data preparation
# 1. NA is assigned to survey response codes pertaining to nonresponse
# 2. low birth weight if 5.5 pounds or less
# 3. impoverished if total_income is...
#     a. lower than federal poverty line or...
#     b. if received tanf_afdc or...
#     c. if received foodstamps or...
#     d. if received lowinc_supp
names(mydata)[names(mydata) == "Y4281900"] <- "highest_school_2016"
mydata$id_sib1[mydata$id_sib1 == -7] <- NA
mydata$id_sib2[mydata$id_sib2 == -7] <- NA
mydata$sex[mydata$sex == -3] <- NA
mydata$mother_age[mydata$mother_age == -3] <- NA
mydata$birthweight_oz[mydata$birthweight_oz == -1] <- NA
mydata$birthweight_oz[mydata$birthweight_oz == -2] <- NA
mydata$birthweight_oz[mydata$birthweight_oz == -3] <- NA
mydata$birthweight_oz[mydata$birthweight_oz == -7] <- NA
mydata$birthweight_low[mydata$birthweight_low == -1] <- NA
mydata$birthweight_low[mydata$birthweight_low == -2] <- NA
mydata$birthweight_low[mydata$birthweight_low == -3] <- NA
mydata$birthweight_low[mydata$birthweight_low == -7] <- NA
mydata$total_income[mydata$total_income == -1] <- NA
mydata$total_income[mydata$total_income == -2] <- NA
mydata$total_income[mydata$total_income == -7] <- NA
mydata$rec_unemp[mydata$rec_unemp == -1] <- NA
mydata$rec_unemp[mydata$rec_unemp == -2] <- NA
mydata$rec_unemp[mydata$rec_unemp == -7] <- NA
mydata$rec_tanf_afdc[mydata$rec_tanf_afdc == -1] <- NA
mydata$rec_tanf_afdc[mydata$rec_tanf_afdc == -2] <- NA
mydata$rec_tanf_afdc[mydata$rec_tanf_afdc == -7] <- NA
mydata$rec_snap_foodstamp[mydata$rec_snap_foodstamp == -1] <- NA
mydata$rec_snap_foodstamp[mydata$rec_snap_foodstamp == -2] <- NA
mydata$rec_snap_foodstamp[mydata$rec_snap_foodstamp == -7] <- NA
mydata$highest_school[mydata$highest_school == -1] <- NA
mydata$highest_school[mydata$highest_school == -2] <- NA
mydata$highest_school[mydata$highest_school == -7] <- NA
mydata$highest_school_2016[mydata$highest_school_2016 == -7] <- NA
mydata$rec_lowinc_supp_machine[mydata$rec_lowinc_supp_machine == -7] <- NA
mydata$highest_school <- ifelse(!is.na(mydata$highest_school), 
                                mydata$highest_school, 
                                mydata$highest_school_2016)
mydata$highest_school_2016 <- NULL

mydata$female <- ifelse(mydata$sex == 2, 1, 0)
mydata$is_sibpair <- ifelse(!is.na(mydata$id_sib1) & is.na(mydata$id_sib2),1,0)
mydata$impov <- ifelse(mydata$total_income <= 26200
                       | mydata$rec_tanf_afdc == 1
                       | mydata$rec_snap_foodstamp == 1, 1, 0)


# subset the data - 2881 observations
# 1. interested in the effects of early life events on later life outcomes (age 30+)
#     a. to this end, subset for individuals born 1991 or earlier
# 2. want to exclude any observations for which response variable is NA
# 3. also exclude observations for which independent vars are NA
sub <- mydata %>%
  filter(birthyear <= 1991) %>%
  filter(!is.na(impov)) %>%
  filter(!is.na(birthweight_low)) %>%
  filter(!is.na(highest_school))

summary(sub)
contrasts(factor(sub$highest_school))


# regress impov on birthweight_low and highest_school
mod1 <- glm(impov ~ birthweight_low + factor(highest_school) + factor(race) + female,
            data = sub, family = "binomial")

mod2 <- glm(impov ~ birthweight_low + factor(race) + female,
            data = sub, family = "binomial")

mod3 <- glm(impov ~ birthweight_low,
            data = sub, family = "binomial")


summary(mod1)
vif(mod1)

summary(mod2)
vif(mod2)

summary(mod3)

# interpretation of log odds: 1 unit increase leads to e^coeff multiplied to odds
# interpretation of Alaike information criterion (AIC) - relative measure, lower is better
# 1. in this regard, mod1 is the best, slightly better than the others


