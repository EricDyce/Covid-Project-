--CREATE Database Covid_Project

SELECT *
FROM Covid_Project.dbo.Coviddeaths
ORDER BY 3,4

SELECT *
FROM Covid_Project..Covidvaccination

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Coviddeaths
ORDER BY 1,2

--------------------------------------
--Evaluating total cases vs total deaths
SELECT location, date, total_cases, total_deaths, (total_deaths *100)/total_cases AS death_percentage
FROM Coviddeaths
WHERE total_cases != 0 AND total_deaths != 0 AND location like '%rus%'
ORDER BY 5 desc

SELECT total_cases, total_deaths
FROM Coviddeaths
WHERE total_deaths != 0
ORDER BY 1,2

-- CAST (total_deaths as int)
-- CONVERT (int, total_deaths)
-- SUM(total_deaths) OVER (Partition by location)  # adds up successive total_deaths like in an iteration, a rolling count


SELECT cv.date, cd.location, population_density, population
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.iso_code = cd.iso_code AND cv.date = cd.date

SELECT cd.location, SUM(CAST(total_vaccinations AS float)) AS Vaccinations , SUM(CAST(population AS float)) AS 'Population'
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.iso_code = cd.iso_code AND cv.date = cd.date
GROUP BY cd.location
ORDER BY 1

-- the SUM(x) OVER (partition by location) increments the value of the new column on each instance of x for a given location
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(new_vaccinations AS float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS IncPplVaccinated
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent != ' '
ORDER BY 2,3

-- here we want to determine % of population vaccinated in each country using the created IncPplVaccinated column
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(new_vaccinations AS float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS IncPplVaccinated,
MAX(CONVERT(float, IncPplVaccinated))/cd.population
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent != ' '
ORDER BY 2,3

--------------------------
-- Using CTE
with PopVaccd (continent,location, date, population, new_vaccinations, IncPplVaccinated)
-- the number of columns in the cte must be equal to that in the statement
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(new_vaccinations AS float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS IncPplVaccinated
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent != ' '
--ORDER BY 2,3
)

SELECT *, ((CONVERT(float, IncPplVaccinated))/population) *100 AS '%Vaccinated'
FROM PopVaccd
where IncPplVaccinated != 0 and population != 0

--------------------------
-- Using Temp Table
DROP TABLE IF EXISTS PopVacd
CREATE TABLE PopVacd (
continent nvarchar(150),
location varchar(150), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
IncPplVaccinated numeric)

INSERT INTO PopVacd
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(new_vaccinations AS float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS IncPplVaccinated
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent != ' '
--ORDER BY 2,3

SELECT *, ((CONVERT(float, IncPplVaccinated))/population) *100 AS '%Vaccinated'
FROM PopVacd
where IncPplVaccinated != 0 and population != 0


-- Creating Views to store data for later visualizations
CREATE VIEW PercentPopulationVaccd AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CAST(new_vaccinations AS float)) OVER (Partition by cd.location ORDER BY cd.location, cd.date) AS IncPplVaccinated
FROM Covidvaccination cv JOIN Coviddeaths cd
ON cv.location = cd.location AND cv.date = cd.date
WHERE cd.continent != ' '