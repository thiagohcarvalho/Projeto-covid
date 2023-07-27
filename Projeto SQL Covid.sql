SELECT *
FROM [Projeto-covid]..CovidDeaths
ORDER BY 3,4

-- General look at the data the we're going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Projeto-covid]..CovidDeaths
ORDER BY Location, date


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you had covid in any country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Projeto-covid]..CovidDeaths
-- WHERE Location = 'Brazil'
WHERE continent is not null
ORDER BY Location, date


-- Looking at Total Cases vs Population 
-- Shows the percentage of population that got covid in any country

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopulationPercentage
FROM [Projeto-covid]..CovidDeaths
WHERE Location = 'United States'
ORDER BY Location, date


-- Looking at countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPopulationPercentage
FROM [Projeto-covid]..CovidDeaths
GROUP BY Location, population
ORDER BY InfectedPopulationPercentage desc



-- Countries with highest death count per population

SELECT Location, population, MAX(cast(total_deaths AS int)) AS TotalDeathCount, MAX((total_deaths/population))*100 AS DeathPerPopulation
FROM [Projeto-covid]..CovidDeaths
WHERE continent is not null
GROUP BY Location, population
ORDER BY DeathPerPopulation desc


-- Breaking down by continent


-- Showing continents with highest death count per population

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM [Projeto-covid]..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Global numbers


-- Showing how many cases and death per day, along with the percentage of deaths by case
SELECT date, SUM(new_cases) AS Cases_per_day, SUM(cast(new_deaths AS int)) Deaths_per_day, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM [Projeto-covid]..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY date

-- How many cases, deaths and the percentage of deaths by case altogether
SELECT SUM(new_cases) AS Cases_per_day, SUM(cast(new_deaths AS int)) AS Deaths_per_day, (SUM(cast(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM [Projeto-covid]..CovidDeaths
WHERE continent is not null

SELECT MAX(total_cases), MAX(cast(total_deaths AS int)) Deaths_per_day, (MAX(cast(total_deaths AS int))/MAX(total_cases))*100 AS DeathPercentage
FROM [Projeto-covid]..CovidDeaths
WHERE continent is null


-- Looking at Total Population vs Vaccinations

-- This doesn't work because you can't SELECT a table that doesn't exist (RollingPeopleVaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
, (PercentagePeopleVaccinated/population)*100 
FROM [Projeto-covid]..CovidDeaths dea
JOIN [Projeto-covid]..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY dea.location, dea.date

-- To work around this issue, there are two options
-- USING CTE

WITH PopulationVsVaccination (continent, location, date, population, new_vaccinations, PercentagePeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PercentagePeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 
FROM [Projeto-covid]..CovidDeaths dea
JOIN [Projeto-covid]..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY dea.location, dea.date
)
SELECT *, (PercentagePeopleVaccinated/population)*100 
FROM PopulationVsVaccination

-- Or we can use a
-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
PercentagePeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PercentagePeopleVaccinated
FROM [Projeto-covid]..CovidDeaths dea
JOIN [Projeto-covid]..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY dea.location, dea.date

SELECT *, (PercentagePeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated


-- Creating view to store data for visualizations
USE [Projeto-covid]
DROP VIEW PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PercentagePeopleVaccinated
FROM [Projeto-covid]..CovidDeaths dea
JOIN [Projeto-covid]..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
-- ORDER BY dea.location, dea.date

SELECT *
FROM PercentPopulationVaccinated






-- QUERIES TO BE USED IN TABLEAU
-- 1. Sum of all cases, deaths and percentage of deaths by case

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM [Projeto-covid]..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- 2. Total death count by continent

SELECT location, SUM(cast(new_deaths AS int)) AS TotalDeathCount
FROM [Projeto-covid]..CovidDeaths
WHERE continent is null AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount desc


-- 3. Highest percentage of population infected

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM [Projeto-covid]..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


-- 4. Highest percentage of population infected each date


SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM [Projeto-covid]..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentPopulationInfected desc