
-- Covid 19 Data Exploration

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4


-- Select Data that we are going to be starting with.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Total Cases vs Total Deaths.
-- Shows the liklihood of dying if you contract Covid in a specific country.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
and continent is not null
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%' -- Looking at the United States.
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population,  MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' -- Looking at the United States.
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount -- Cast Total_deaths as int
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%' -- Looking at the United States.
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT
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



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- We used CAST, Partition, and ROLLING COUNT

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



-- Using CTE to perform Calculation on Partition By in previous query
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
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(INT, vac.new_vaccinations)) OVER (partition by dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea -- Alias (dea)
JOIN PortfolioProject.. CovidVaccinations vac -- Alias (vac)
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
