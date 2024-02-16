-- Confirming that data import (.xlsx) worked without issue
-- Query ALL rows here just to make sure nothing is missing
-- NOTE: Dates were broken on initial import
---- required manipulation in excel before reimport
-- NOTE: When continent IS NULL, data is tracked by larger geogrpahic groupings
SELECT *
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
;
SELECT *
FROM CovidProject..CovidVaccinations
WHERE continent IS NULL
ORDER BY location, date
;


-- Looking at how this data is structured
-- NOTE: Tending to find NULLs towards the start and end of data reported by each location
---- early NULLs likely a result of a simple lack of data
---- later NULLs likely a result of OWID data collection methods
-- NOTE: Data updates appear to swap from daily to weekly basis
---- this tends to occur later into pandemic response
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
---- confirmed to be a 7-day rolling average (https://github.com/owid/covid-19-data/blob/master/public/data/README.md)
-- Some locations stop reporting on new tests and new vaccinations mid~late 2022
---- South Korea stops reporting new tests 2022-06-16, new vaccinations 2022-12-13
---- similar in data from other locations - various columns, varying dates
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
-- Calculated DeathRate (%)
---- shows likelihood of dying if infected with COVID
-- Datatype recasting due to some numeric data being imported as nvarchar
SELECT location
	 , date
	 , total_cases
	 , total_deaths
	 , (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS 'DeathRate (%)'
FROM CovidProject..CovidDeaths
WHERE location = 'South Korea'
ORDER BY location, date
;


-- Looking at Total Cases vs Population
-- Calculated InfectionRate (%)
---- shows what percentage of population was infected with COVID
-- Datatype recasting due to some numeric data being imported as nvarchar
SELECT location
	 , date
	 , total_cases
	 , population
	 , (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS 'InfectionRate (%)'
FROM CovidProject..CovidDeaths
WHERE location = 'South Korea'
ORDER BY location, date
;


-- Looking at countries with highest Infection Rate compared to Population
SELECT location
	 , population
	 , MAX(CAST(total_cases AS float)) AS HighestInfectionCount
	 , MAX(CAST(total_cases AS float) / CAST(population AS float)) * 100 AS 'InfectionRate (%)'
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 'InfectionRate (%)' DESC
;


-- Looking at countries with highest Death Count
SELECT location
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;


-- Looking at continents with highest Death Count
-- NOTE: seeing different results with the two queries below
---- using continent and continent IS NOT NULL:
------ several continent groups only count data from one country within their region
---- using location and continent IS NULL: 
------ North American TotalDeathCount appears to accurately count beyond the USA
---- slightly odd, but now I know to use the latter method when trying to look at the data by continent
SELECT continent
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
;
SELECT location
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE location IN ('United States', 'Brazil', 'Russia')
GROUP BY location
ORDER BY TotalDeathCount DESC
;
SELECT location
	 , MAX(CAST(total_deaths AS float)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;


-- Looking at global daily total DeathRate over time
-- Calculated DeathRate (%)
---- shows likelihood of dying if infected with COVID
-- Trying a CTE to summarize global data before calculating daily DeathPercentage
-- Trying a CASE statement to avoid divide by zero errors
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


-- Looking at global total DeathRate overall
-- Calculated DeathRate (%)
---- shows likelihood of dying if infected with COVID
-- Trying a CTE to summarize global data before calculating daily DeathPercentage
-- Trying a CASE statement to avoid divide by zero errors
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


-- Looking at Total Population vs Vaccinations
-- NOTE: new_vaccinations column contains NULLs when there are gaps in daily reporting
---- should be easier to track this data visually over time without these gaps
---- implementing a rolling sum should at least give us a data point for each day
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
-- NOTE: RollingVaccinationRate occasionally exceeds 100%
---- this is due to second doses and booster shots being counted as new vaccinations
---- using SUM(people_vaccinated) OVER... might be more appropriate for a visualizing this data
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

SELECT *, (RollingVaccinations / Population) * 100 AS 'RollingVaccinationRate (%)'
FROM rollvac
ORDER BY Continent, Location, Date
;


-- Looking at People Vaccinated vs Population
-- A vaccination rate calculated using this data shouldn't exceed 100% as before
-- The new_people_vaccinated_smoothed column contains a 7-day rolling average
---- a rolling sum of this smoothed data would visually appear as though it is being updated more regularly
---- this seems useful for overcoming visible gaps in data reporting frequency
-- Can place this query in a CTE and calculate a new RollingVaccinationRate 
WITH rollnpvac (Continent, Location, Date, Population, People_Vaccinated, New_People_Vaccinated_Smoothed, RollingPeopleVaccinated) AS (
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.people_vaccinated
	 , cv.new_people_vaccinated_smoothed
	 , SUM(CAST(cv.new_people_vaccinated_smoothed AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS 'RollingVaccinationRate (%)'
FROM rollnpvac
ORDER BY Continent, Location, Date
;


-- Reimplementing above query with a temp table instead of a CTE
-- Temp tables are automatically purged at the end of each session
---- they do persist across transactions in the same session
-- DROP TABLE IF EXISTS #PopulationVaccinated
CREATE TABLE #PopulationVaccinated (
Continent nvarchar(255)
, Location nvarchar(255)
, Date datetime
, Population numeric
, People_Vaccinated numeric
, New_People_Vaccinated_Smoothed numeric
, RollingPeopleVaccinated numeric
)

INSERT INTO #PopulationVaccinated
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.people_vaccinated
	 , cv.new_people_vaccinated_smoothed
	 , SUM(CAST(cv.new_people_vaccinated_smoothed AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS 'RollingVaccinationRate (%)'
FROM #PopulationVaccinated
ORDER BY Continent, Location, Date
;


-- Creating a View to utilize in visualization software
-- DROP VIEW IF EXISTS PctPopulationVaccinated
CREATE VIEW PctPopulationVaccinated AS
SELECT cd.continent
	 , cd.location
	 , cd.date
	 , cd.population
	 , cv.people_vaccinated
	 , cv.new_people_vaccinated_smoothed
	 , SUM(CAST(cv.new_people_vaccinated_smoothed AS FLOAT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
;

SELECT *
FROM PctPopulationVaccinated