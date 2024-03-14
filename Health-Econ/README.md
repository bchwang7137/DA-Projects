# Health Economics

## Description
This data project utilizes R to explore the long-term effects of low weight at birth on lifetime exposure to poverty using the NLSY79 Child and Young Adult dataset. Low birth weight (less than 2500 grams at birth) is often cited as a strong indicator of early childhood health and a powerful predictor of an infant's life outcomes during their first year of life. This study investigates the relationship between low birth weight and later life socioeconomic outcomes, implementing logistic regression models and controls for race, sex, and educational attainment.

Initial results indicate a significant positive association between low birth weight and poverty exposure. However, once controlling for additional confounds such as race and education level, the relationship becomes statistically insignificant. This suggests that while low birth weight may initially appear to directly influence lifetime socioeconomic outcomes, other variables might play a more significant role. 

Further research might involve exploring whether low birth weight affects later life socioeconomic outcomes indirectly through its influence on relevant factors such as educational attainment. Model summaries and additional discussion are available in the attached paper.

## Data Source
- U.S. Bureau of Labor Statistics NLSY79 Child and Young Adult Cohort: [Link](https://www.bls.gov/nls/nlsy79-children.htm)
- Data Fetch Date: May 10, 2021

## Poverty and Low Birthweight
- Code: [PovertyLowBirthweight.R](PovertyLowBirthweight.R)
- Final Term Paper: [ECON 4160 Final Paper Submission.pdf](ECON-4160-Final-Paper-Submission.pdf)
