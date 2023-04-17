SELECT *
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
;

--SELECT *
--FROM CovidProject..CovidVaccinations
--ORDER BY location, date
--;

-- Select Data that we are going to be using
SELECT location
	 , date
	 , total_cases
	 , new_cases
	 , total_deaths
	 , population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date
;


-- Looking at Total Cases vs Total Deaths 
-- Shows the likelihood of dying if infected with COVID, by country
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


-- Looking at global numbers by date
SELECT date
	 , GlobalDailyCases
	 , GlobalDailyDeaths
	 , CASE 
		WHEN GlobalDailyCases != 0 THEN (GlobalDailyDeaths / GlobalDailyCases) * 100 
		ELSE 0
	   END AS DeathPercentage
FROM (
	SELECT date
		 , SUM(CAST(new_cases AS float)) AS GlobalDailyCases
		 , SUM(CAST(new_deaths AS float)) AS GlobalDailyDeaths
	FROM CovidProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY date) AS glob
ORDER BY date
;


-- Looking at global numbers overall
SELECT GlobalCases
	 , GlobalDeaths
	 , CASE 
		WHEN GlobalCases != 0 THEN (GlobalDeaths / GlobalCases) * 100
		ELSE 0
	   END AS DeathPercentage
FROM (
	SELECT SUM(CAST(new_cases AS float)) AS GlobalCases
		 , SUM(CAST(new_deaths AS float)) AS GlobalDeaths
	FROM CovidProject..CovidDeaths
	WHERE continent IS NOT NULL) AS glob
;


-- Looking at Total Population vs Vaccinations
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
-- Querying with SUM(people_vaccinated) might be more useful for visualizations later on
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


-- Repeating the above query with a Temp Table instead of a CTE
DROP TABLE IF EXISTS #PopulationVaccinations
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


-- Creating view to store for later visualizations
DROP VIEW IF EXISTS PctPopulationVaccinated
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


-- TASK: Create a number of views containing data that might be interesting to use in tableau 
-- consider the ability to drill down - global, continent, country scale
-- consider what is interesting about the covid pandemic + response in retrospect
-- specific spikes, important dates to highlight?
-- important ratios to calculate and track over time?
-- test
