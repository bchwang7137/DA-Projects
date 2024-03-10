# Health Economics

## Description
This data project utilizes R to prepare and analyze data from the NLSY79 Child and Young Adult dataset with the aim of investigating the lasting effects that unequal health at the 'starting gate' of life can have on socioeconomic outcomes that manifest in the later stages of an individual's lifetime. In particular, it studies the relationship between low birth weight and lifetime exposure to poverty. The data is sourced from the National Longitudinal Surveys (NLS), which a set of surveys sponsored by the U.S. Bureau of Labor Statistics. This study focuses on a particular survey which tracks a sample of children biennially and covers a range of socioeconomic and health-related information including birth weight, income, and educational attainment.

After cleaning and processing the dataset, I defined a binary response variable representing a survey respondent's exposure to poverty by applying federal poverty thresholds to their reported total income and referencing records of participation in federal low-income assistance programs. I proceeded to generate a series of dummy variables to control for respondent birth weight, race, sex, and educational attainment. I then created a subset of the data to focus on respondents born in the year 1991 or earlier. This was done in the interest of exploring the effects of low birth weight on later life outcomes for individuals aged thirty or older at the time of the 2018 NLSCYA survey.

## Data Source
- U.S. Bureau of Labor Statistics NLSY79 Child and Young Adult Cohort: [Link](https://www.bls.gov/nls/nlsy79-children.htm)
- Data Fetch Date: May 10, 2021

## Poverty and Low Birthweight
- Code: [PovertyLowBirthweight.R](PovertyLowBirthweight.R)
