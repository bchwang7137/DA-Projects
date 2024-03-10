# COVID-19 Data Projects

## Description
These data projects primarily utilize SQL and Tableau to analyze and visualize the Our World in Data COVID-19 Dataset. This comprehensive dataset contains information on confirmed cases, deaths, hospitalizations, vaccinations, and various other metrics pertinent to the global COVID-19 pandemic. The overall goal of this project is to create interactive and informative dashboards that depict the evolving severity of the pandemic over time, particularly before and after the development and deployment of different COVID-19 vaccines. Additionally, the project aims to highlight the notable disparities in vaccination program progress across various countries.

I initiated the project by conducting an initial examination of the dataset using Microsoft Excel. Then, I utilized the import/export tool within MS SQL Server to import the dataset into a database. I organized the data into two distinct tables focusing on COVID-19 cases and deaths, as well as COVID-19 vaccinations. Exploring the dataset further, I wrote a series of SQL queries to gain a better understanding of its structure. After planning out my approach for each aspect of the project, I created individuals scripts to query and extract only the essential data for each dashboard which helped me streamline my workflow within Tableau.

By combining SQL for data manipulation and Tableau for visualization, this project aims to provide a dynamic exploration of the COVID-19 pandemic, looking at both its changing severity over time and the differences in vaccination efforts worldwide.

## Data Source
- Our World in Data COVID-19 Dataset: [Link](https://github.com/owid/covid-19-data/tree/master/public/data)
- Data Fetch Date: December 6, 2023

## COVID-19 Data Exploration
- Code: [DataExploration.sql](DataExploration.sql)

## COVID-19 Global Case Fatality Rate Dashboard
- Code: [Covid19GlobalCFRDB.sql](Covid19GlobalCFRDB.sql)
- Dashboard Link: [Link](https://public.tableau.com/views/COVID-19GlobalCFRDB/GlobalCOVID-19CFRDB?:language=en-US&:display_count=n&:origin=viz_share_link)

## COVID-19 Global Vaccine Inequality Dashboard
- Code: [COVID19GlobalVaccDB.sql](COVID19GlobalVaccDB.sql)
- Dashboard Link: [Link](https://public.tableau.com/views/COVID-19GlobalVaccInequalityDB/GlobalCOVID-19VaccIneqDB?:language=en-US&:display_count=n&:origin=viz_share_link)
