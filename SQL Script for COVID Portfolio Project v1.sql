SELECT *
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM CovidPortfolioProject..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT DISTINCT location
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

--Looking at total cases vs total deaths in the US
--Shows likelihood of dying with a positive case in the US
SELECT location, date, total_cases, total_deaths,
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) *100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1, 2

--Looking at total cases vs population
--Shows what percentage of the population got Covid in the US
SELECT location, date, population, total_cases, 
	(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) *100 AS InfectionRate
FROM CovidPortfolioProject..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1, 2

--Looking at countries with highest infection rate	
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) *100 AS InfectionRate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, total_deaths
ORDER BY InfectionRate desc


--Showing countries with highest death count by population
SELECT location, MAX(cast(total_deaths AS bigint)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc


--BREAKING THINGS DOWN BY CONTINENT

--This isn't getting us the right numbers because it's using the MAX but not adding
SELECT continent, MAX(cast(total_deaths AS bigint)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

--This is getting us the right numbers, but is including categories that aren't continents like "low income"
--Using this may also mess up our Tableau visualizations when we get to that
SELECT location, MAX(cast(total_deaths AS bigint)) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--This is the correct code!!! The numbers are very close to the previous code chunk
SELECT DISTINCT continent, SUM(new_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc


--Showing continents with the highest death rate by population
SELECT continent, SUM(new_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc


--Global Numbers

--Looking at total cases vs total deaths
--Shows likelihood of dying with a positive case
SELECT date, SUM(new_cases) AS NewCases, SUM(new_deaths) AS NewDeaths,
SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


--Looking at total cases vs total deaths
--Shows likelihood of dying with a positive case
SELECT SUM(new_cases) AS NewCases, SUM(new_deaths) AS NewDeaths,
SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1


--Joining tables

--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingTotalVaccinations, --(RollingTotalVaccinations/population)*100
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3	


--Using a CTE
WITH PopVsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingTotalVaccinations--, (RollingTotalVaccinations/population)*100
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePopulationVaccinated
FROM PopVsVac



--Using at Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingTotalVaccinations--, (RollingTotalVaccinations/population)*100
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingTotalVaccinations/Population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2, 1, 3

--Creating a view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingTotalVaccinations--, (RollingTotalVaccinations/population)*100
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated