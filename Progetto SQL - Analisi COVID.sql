SELECT *
from PortfolioProject..CovidDeaths
WHERE continent is not null
order by 3, 4

--SELECT *
--from PortfolioProject..CovidVaccinations
--order by 3, 4

-- Seleziono i dati che andrò a usare

SELECT Location, Date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
WHERE continent is not null
order by 1, 2

-- Confronto i casi totali con i decessi totali
-- Mostra la possibilità di morire se contrai il covid nel tuo Paese

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
WHERE location like '%ital%'
order by 1, 2

-- Confronto i casi totali vs la popolazione
-- Mostra la percentuale di popolazione che ha preso il covid

SELECT Location, Date, Population, total_cases, total_deaths, (total_cases/Population)*100 AS PercentPopulationInfected
from PortfolioProject..CovidDeaths
WHERE continent is not null
--WHERE location like '%ital%'
order by 1, 2


-- Cerco i Paesi con il tasso di infezione più alto rispetto alla popolazione

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS PercentPopulationInfected
from PortfolioProject..CovidDeaths
--WHERE location like '%ital%'
WHERE continent is not null
group by location, population
order by PercentPopulationInfected DESC

-- Mostro i Paesi con il maggior numero di decessi per popolazione

SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--WHERE location like '%ital%'
WHERE continent is not null
group by location, population
order by TotalDeathCount DESC


-- Mostro i Continenti con il più alto numero di decessi per popolazione

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--WHERE location like '%ital%'
WHERE continent is not null
group by continent
order by TotalDeathCount DESC


-- NUMERI SU SCALA GLOBALE
-- Percentuale di decessi per casi giorno per giorno


SELECT date, Sum(new_cases) AS total_cases, Sum(Cast(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM   portfolioproject..coviddeaths
--WHERE location like '%ital%'
WHERE  continent IS NOT NULL
GROUP  BY date
ORDER  BY 1, 2 

-- Percentuale di decessi per casi totali cumulato

SELECT Sum(new_cases) AS total_cases, Sum(Cast(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM   portfolioproject..coviddeaths
--WHERE location like '%ital%'
WHERE  continent IS NOT NULL
ORDER  BY 1, 2 


-- Mostro la popolazione totale vs i totali vaccinati.
-- 1° Step: creo la colonna dei vaccinati a progressivo data

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date	
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Mostro la popolazione totale vs i totali vaccinati.
-- 2° Step: creo la colonna della percentuale vaccinati usando una CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date	
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS Percentage
FROM PopVsVac

-- Faccio la stessa cosa ma con una TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date	
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100 AS Percentage
FROM #PercentPopulationVaccinated

-- Creo una Vista per conservare i dati

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date	
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated