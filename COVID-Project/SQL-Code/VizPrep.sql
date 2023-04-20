-- TASK: Create a number of views containing data that might be interesting to use in tableau 
-- consider the ability to drill down - global, continent, country scale
-- consider what is interesting about the covid pandemic + response in retrospect
-- specific spikes, important dates to highlight?
-- important ratios to calculate and track over time?

-- WHAT are some questions that I want to answer with this data?
-- 1. how 'serious' was the pandemic in certain locations over certain periods of time?
--    a. location filter: continent -> country
--    b. date filter: start date -> end date
--    c. a suite of charts that track certain metrics over time
--        1. multiple-line chart - total tests, total cases, daily new tests, daily new cases, positivity rate
--        2. multiple-line chart - hospitalization, 
--    d. a set of key KPI figures calculated for overall metrics for the location during the period (3~4?)
-- 2. how is the COVID situation in South Korea for the past month? past year?
--    a. less interactive, fixed set of information
--    b. new case trends, new death trends, hospitalization trends, vaccination trends (partial vaccination and full vaccination)

-- some dates have NULL data - not every location reported covid data on a daily basis
-- use rolling sums to 'populate' NULL fields for visualization purposes

-- consider that detected case numbers underestimate true case numbers
-- same goes for reported deaths - excess deaths paints a truer picture
-- not everyone who is infected is going to seek out a test
-- also consider that pandemics are complex phenomena that are difficult to summarize with a single metric
-- good to use a balanced 'portfolio' of metrics to track pandemic 
-- important to consider 'big picture' trends and metrics instead of daily numbers, especially when considering high-stakes policy responses

-- tracking case counts and test counts together can help explain changes in case counts
	-- if case counts and test counts both rise... - a good thing, infected people are being identified and care will be provided
	-- if case counts rise but test counts dont... - infection transmission may be rising
	-- if case counts stagnate and test counts fall... - increase test supply

-- tracking positivity rate (positive case count / test count) can alleviate spikes when more tests are avail
-- tracking change over time can be useful, but the metric itself isn't super meaningful
-- is 1% to 2% actionable?


-- metrics by high, med, low income
-- case fatality, vaccine proliferation (people vaccinated), 

-- metrics by location (world > continent > country)
-- note: continent is not null




-- data as of: 2023-04-06 00:00:00

-- First, a simple global snapshot
-- Q: How was the global COVID situation over the past week? (as of 2023-04-06)

-- Issue: There are gaps in the reported data - appears that some countries stop reporting certain kinds of data at different dates
-- Soln: Implement a MAX() window function to obtain the last known/reported value for certain columns
-- Seems like an adequate solution since we wouldn't expect the total count of vaccine doses, deaths, etc. to decrease over time
	-- Does not apply to new cases and new deaths as these numbers can increase or decrease on a daily basis
-- This 'workaround' sacrifices some accuracy - the numbers won't always perfectly reflect reality
-- Still useful in presenting a more consistent snapshot of the latest available information per country for comparison

-- IN TABLEAU:
	-- at the top: a collection of global KPIs - cumulative cases, cumulative deaths, total vaccine doses administered
	-- a world map with toggle filters (?) to show total case counts, death counts, vaccination progress etc. with color scales for comparison
	-- a table containing the 'most recent' numbers for each column
		-- daily cases, deaths summed and presented as 'Cases_LastWeek' or similar
	-- footnote (or header?) regarding last data update and data source

--DROP VIEW IF EXISTS Global_Covid_1Week_Snapshot_20230406
CREATE VIEW Global_Covid_1Week_Snapshot_20230406 AS 
WITH global1year AS (
	SELECT cd.location
		 , CONVERT(DATE, cd.date) AS date
		 , cd.population
		 , MAX(CAST(cd.total_cases AS float)) OVER (
			PARTITION BY cd.location ORDER BY cd.date ROWS UNBOUNDED PRECEDING
			) AS cases_total
		 , cd.new_cases AS cases_new
		 , MAX(CAST(cd.total_deaths AS float)) OVER (
			PARTITION BY cd.location ORDER BY cd.date ROWS UNBOUNDED PRECEDING
			) AS deaths_total
		 , cd.new_deaths AS deaths_new
		 , MAX(CAST(cv.total_vaccinations AS float)) OVER (
			PARTITION BY cd.location ORDER BY cd.date ROWS UNBOUNDED PRECEDING
			) AS vaccinations_total
		 , MAX(CAST(cv.people_fully_vaccinated AS float)) OVER (
			PARTITION BY cd.location ORDER BY cd.date ROWS UNBOUNDED PRECEDING
			) AS people_fully_vaccinated_total
		 , MAX(CAST(cv.total_boosters AS float)) OVER (
			PARTITION BY cd.location ORDER BY cd.date ROWS UNBOUNDED PRECEDING
			) AS boosters_total
	FROM CovidProject..CovidDeaths AS cd
	JOIN CovidProject..CovidVaccinations AS cv
		ON cd.location = cv.location
		AND cd.date = cv.date
	WHERE cd.date BETWEEN DATEADD(YEAR, -1, '2023-04-06') AND '2023-04-06'
		AND cd.continent IS NOT NULL
)

SELECT Location
	 , Date
	 , cases_total AS Cases_Total
	 , cases_new AS Cases_New
	 , deaths_total AS Deaths_Total
	 , deaths_new AS Deaths_New
	 , ROUND((vaccinations_total / population) * 100, 2) AS Vaccinations_Per_Hundred_Pop
	 , ROUND((people_fully_vaccinated_total / population) * 100, 2) AS People_Fully_Vaccinated_Per_Hundred_Pop
	 , ROUND((boosters_total / population) * 100, 2) AS Boosters_Per_Hundred_Pop
FROM global1year
WHERE date BETWEEN DATEADD(WEEK, -1, '2023-04-06') AND '2023-04-06'
;