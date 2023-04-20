-- Confirming that data import (.xlsx) worked without issue
-- Note that dates were breaking on import
-- Required manipulation in excel before reimport
SELECT *
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
;
SELECT *
FROM CovidProject..CovidVaccinations
ORDER BY location, date
;


-- Looking at how this data is structured
-- Note NULLs towards the start and end of data reported by each location
-- Occasionally, data reported from some locations switches between daily and weekly basis
SELECT location
	 , date
	 , total_cases
	 , new_cases
	 , total_deaths
	 , population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
	AND location = 'South Korea'
ORDER BY location, date
;


-- Investigating what 'smoothed' data looks like
-- Initial observation suggests a rolling average calculated using a set range of days
-- Confirmed to be a 7-day rolling average (https://github.com/owid/covid-19-data/blob/master/public/data/README.md)
-- Some locations stop reporting on new tests and new vaccinations mid~late 2022
-- South Korea stops reporting new tests 2022-06-16, new vaccinations 2022-12-13
-- Similar in data from other locations, various columns, varying dates
SELECT cd.location 
	 , cd.date
	 , cd.new_cases, cd.new_cases_smoothed
	 , cd.new_deaths, cd.new_deaths_smoothed
	 , cv.new_tests, cv.new_tests_smoothed
	 , cv.new_vaccinations, cv.new_vaccinations_smoothed
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
	AND cd.location IN ('South Korea', 'Japan')
ORDER BY location, date
;


-- Looking at Total Cases vs Total Deaths 
-- Shows the likelihood of dying if infected with COVID
-- Datatype recasting due to some numeric data being imported as nvarchar
SELECT location
	 , date
	 , total_cases
	 , total_deaths
	 , (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathRate
FROM CovidProject..CovidDeaths
WHERE location = 'South Korea'
ORDER BY location, date
;


-- Looking at Total Cases vs Population
-- Shows what percentage of population was infected with COVID
SELECT location
	 , date
	 , total_cases
	 , population
	 , (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS InfectionRate
FROM CovidProject..CovidDeaths
WHERE location = 'South Korea'
ORDER BY location, date
;


-- Looking at countries with highest Infection Rate compared to Population
SELECT location
	 , population
	 , MAX(CAST(total_cases AS float)) AS HighestInfectionCount
	 , MAX(CAST(total_cases AS float) / CAST(population AS float)) * 100 AS InfectionRate
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC
;


-- Looking at countries with highest Death Count per Population
SELECT location
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;


-- Looking at continents with highest Death Count per Population
SELECT continent
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
;


-- Looking at global Death Percentage over time
-- CASE statement to avoid divide by zero errors
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
	   END AS DeathPercentage
FROM glob
ORDER BY date
;


-- Looking at global Death Percentage overall
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
	   END AS DeathPercentage
FROM glob
;


-- Looking at Total Population vs Vaccinations
-- Utilizes a SUM() window function to overcome NULLs in the new_vaccinations data
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.new_vaccinations
	 , SUM(CAST(cv.new_vaccinations AS float)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv 
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.continent, cd.location, cd.date
;


-- Looking at Rolling Vaccinations vs Population
-- Note that Rolling Vaccination Rate occasionally exceeds 100
-- This is due to second doses and booster shots being counted as new vaccinations
-- Using SUM(people_vaccinated) OVER... might be more appropriate for visualizations
WITH rollvac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations) AS (
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.new_vaccinations
	 , SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv 
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, (RollingVaccinations / Population) * 100 AS RollingVaccinationRate
FROM rollvac
ORDER BY Continent, Location, Date
;


-- Reimplementing above query with a Temp Table instead of a CTE
-- DROP TABLE IF EXISTS #PopulationVaccinations
CREATE TABLE #PopulationVaccinations (
Continent nvarchar(255)
, Location nvarchar(255)
, Date datetime
, Population numeric
, New_Vaccinations numeric
, RollingVaccinations numeric
)

INSERT INTO #PopulationVaccinations
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.new_vaccinations
	 , SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv 
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (RollingVaccinations / Population) * 100 AS RollingVaccinationRate
FROM #PopulationVaccinations
ORDER BY Continent, Location, Date
;


-- Creating a View to utilize in visualization software
-- DROP VIEW IF EXISTS PctPopulationVaccinated
CREATE VIEW PctPopulationVaccinated AS
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.new_vaccinations
	 , SUM(CAST(cv.new_vaccinations AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingVaccinations
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv 
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
;