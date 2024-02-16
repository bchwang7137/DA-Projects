-- SQL queries for COVID-19 Global Vacc Inequality DB
-- Data source: Our World in Data COVID-19 Dataset


-- Looking at per-country vaccination rates over time
---- used the CAST() function to transform nvarchar(255)s into floats where necessary
---- people_vaccinated refers to people who received at least one vaccine dose
---- people_fully_vaccinated refers to people who received all doses prescribed by initial vaccination protocols
---- used the MAX() window function to "fill in" periodic gaps in data reported by some countries
------ implemented in anticipation of potential difficulties and issues in visualization software
------ did not consider this to be problematic (with this dataset) since population figures are static and vaccination counts only increase over time
-- Looking at per-country case fatality rates (CFR) over time
---- the CFR estimates the likelihood of dying if infected with COVID-19
---- used the SUM() window function to keep a cumulative record of newly reported case and death counts
---- used a CASE expression to calculate CFR while preventing division by zero
-- Looking at per-country gdp per capita
-- Used a CTE to summarize relevant daily per-country data before calculating rates
WITH infoprep AS (
SELECT cd.continent AS continent
	 , cd.location AS location
	 , cd.population AS population
	 , cv.gdp_per_capita AS gdp_per_capita
	 , cd.date AS date
	 , CAST(cv.people_vaccinated AS FLOAT) AS CumAnyVacc
	 , CAST(cv.people_fully_vaccinated AS FLOAT) AS CumFullVacc
	 , SUM(cd.new_cases) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS CumCases
	 , SUM(cd.new_deaths) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS CumDeaths
FROM CovidProject..CovidDeaths AS cd
JOIN CovidProject..CovidVaccinations AS cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT continent
	 , location
	 , population
	 , gdp_per_capita
	 , date
	 , CumAnyVacc
	 , MAX(CumAnyVacc) OVER (PARTITION BY location ORDER BY location, date) AS 'NoGap_CumAnyVacc'
	 , ROUND((CumAnyVacc / Population) * 100, 3) AS 'AnyVaccRate (%)'
	 , MAX(ROUND((CumAnyVacc / Population) * 100, 3)) OVER (PARTITION BY location ORDER BY location, date) AS 'NoGap_AnyVaccRate (%)'
	 , CumFullVacc
	 , MAX(CumFullVacc) OVER (PARTITION BY location ORDER BY location, date) AS 'NoGap_CumFullVacc'
	 , ROUND((CumFullVacc / Population) * 100, 3) AS 'FullVaccRate (%)'
	 , MAX(ROUND((CumFullVacc / Population) * 100, 3)) OVER (PARTITION BY location ORDER BY location, date) AS 'NoGap_FullVaccRate (%)'
	 , CumCases
	 , CumDeaths
	 , CASE 
		WHEN CumCases != 0 THEN ROUND((CumDeaths / CumCases) * 100, 3)
		ELSE 0
	   END AS 'CaseFatalityRate (%)'
FROM infoprep
ORDER BY continent, location, date
;


-- Looking at overall vaccination rates (partial and full)
---- people_vaccinated refers to people who received at least one vaccine dose
---- people_fully_vaccinated refers to people who received all doses prescribed by initial vaccination protocols
-- Filtering query results so that continent IS NULL gives us access to the same data, but grouped differently
---- grouped globally and by continent: Africa, Asia, Europe, European Union, North America, Oceania, South America, World
---- grouped by World Bank Group income level: High, Upper middle, Lower middle, Low
---- people_vaccinated refers to people who received at least one vaccine dose
---- people_fully_vaccinated refers to people who received all doses prescribed by initial vaccination protocols
-- Used a CTE and Subquery to summarize daily per-country data before calculating overall global figures
WITH grpdata AS (
	SELECT location AS Grp
		 , MAX(CAST(population AS FLOAT)) AS GroupPop
		 , MAX(CAST(people_vaccinated AS FLOAT)) AS GroupAnyVacc
		 , MAX(CAST(people_fully_vaccinated AS FLOAT)) AS GroupFullVacc
	FROM CovidProject..CovidVaccinations
	WHERE continent IS NULL
	GROUP BY location
)

SELECT Grp
	 , GroupPop
	 , GroupAnyVacc
	 , GroupFullVacc
	 , ROUND((GroupAnyVacc / GroupPop) * 100, 3) AS 'GroupPartVaccRate (%)'
	 , ROUND((GroupFullVacc / GroupPop) * 100, 3) AS 'GroupFullVaccRate (%)'
FROM grpdata
ORDER BY Grp
;
