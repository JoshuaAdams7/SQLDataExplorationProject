--Total Cases vs Total Deaths--
SELECT location, date, total_cases, total_deaths,
(CONVERT(float, total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
AND location = 'United Kingdom'
ORDER BY 1, 2

--Total Cases vs Population--
SELECT location, date, population, total_cases,
(CONVERT(float, total_cases)/NULLIF(CONVERT(float, population), 0))*100 AS PopInfectedPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
AND location = 'United Kingdom'
ORDER BY 1, 2

--Infection Rate vs Population--
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX((CONVERT(float, total_cases))/NULLIF(CONVERT(float, population), 0))*100 AS PopInfectedPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PopInfectedPercentage DESC

--Countries With The Highest Death Count By Population--
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Countries With The Highest Death Count--
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers--
SELECT date, SUM(CAST(new_cases AS INT)) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
NULLIF(SUM(CAST(new_deaths AS INT)), 0)/NULLIF(SUM(CAST(new_cases AS INT)), 0)*100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

--Total Population vs Vaccinations--
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Total Population vs Vaccinations (CTE)--
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/NULLIF(CAST(population AS BIGINT), 0))*100
FROM PopvsVac

--Total Population vs Vaccinations (Temp Table)--
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #RollingPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #RollingPeopleVaccinated

--Creating a View for Data Visualisations--
CREATE VIEW RollingPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
