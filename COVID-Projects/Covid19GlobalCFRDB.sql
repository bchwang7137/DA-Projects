-- SQL queries for COVID-19 Global CFR DB
-- Data source: Our World in Data COVID-19 Dataset


-- Looking at overall global case fatality data
-- Calculated DeathRate (%)
---- this rate estimates the likelihood of dying if infected with COVID-19
---- used a CASE statement to avoid division by zero
-- Used a CTE to summarize relevant global data before calculating rates
WITH glob AS (
	SELECT SUM(CAST(new_cases AS float)) AS GlobalCases
		 , SUM(CAST(new_deaths AS float)) AS GlobalDeaths
	FROM CovidProject..CovidDeaths
	WHERE continent IS NOT NULL
)

SELECT GlobalCases
	 , GlobalDeaths
	 , CASE 
		WHEN GlobalCases != 0 THEN (GlobalDeaths / GlobalCases) * 100
		ELSE 0
	   END AS 'DeathRate (%)'
FROM glob
;


-- Looking at daily global case fatality data over time
-- Includes date column to query data on daily basis instead of aggregating overall
WITH glob AS (
	SELECT date
		 , SUM(CAST(new_cases AS float)) AS GlobalDailyCases
		 , SUM(CAST(new_deaths AS float)) AS GlobalDailyDeaths
	FROM CovidProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY date
)

SELECT date
	 , GlobalDailyCases
	 , GlobalDailyDeaths
	 , CASE 
		WHEN GlobalDailyCases != 0 THEN (GlobalDailyDeaths / GlobalDailyCases) * 100 
		ELSE 0
	   END AS 'DeathRate (%)'
FROM glob
ORDER BY date
;