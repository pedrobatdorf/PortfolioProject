SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows liklihood of dying if you contrat COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
and continent is not null
ORDER BY 1,2


-- Looking at total cases VS Population
-- Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%' -- Looking at the United States.
ORDER BY 1,2


-- Looking at countries with highest infection rate compare to population
SELECT location, population,  MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' -- Looking at the United States.
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing countries with the highest death count per population
SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount -- Cast Total_deaths as int
-- Now we are see weird grouping like continents, we want to see just countries.
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' -- Looking at the United States.
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Lets break things down by continets

SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' 
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC
-- North America is not including Canada

--------------------------- this query above is incorrect ----------------- Below is correct 


SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' 
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Let's break things down by continent


-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' 
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global numbers

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- Looking at total population VS Vaccinations

-- We used CAST, Partition. We did a ROLLING COUNT
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (partition by dea.location)
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Same as above but using a CONVERT
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
WITH PopVsVac (Continent, location, Date, Population,new_vaccinations, RollingPeopleVaccinated)
-- Above Has to be the same number of columns as below or it will show an error
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac



-- TEMP Table
------------------------- Below is NOT working, Video 1:09
DROP TABLE IF EXISTS #PercentPopulationVaccinated -- Delete a table
CREATE TABLE #PercentPopulationVaccinated -- To Make a table
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(INT,vac.new_vaccinations)) OVER (partition by dea.Location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- Creating view to store data for later.

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (partition by dea.Location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated