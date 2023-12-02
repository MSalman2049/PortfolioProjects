-- Prevalence per country at peak Covid case count
select location, max(total_cases) TotalCases, population, (max(total_cases)/population)*100 Prevalence
From CovidDeaths$
Where continent is not null
Group by location, population
Order by location

-- Selecting data that will be used for most of the project. The data covered in this project dates between January 2020, to end of April, 2021
-- Most of the Queries will focus on Canada.

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjectSQL..CovidDeaths$
order by 1,2

-- Looking at Total cases vs Total deaths (DeathRate or DeathPercentage) for all countries

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathRate
From PortfolioProjectSQL..CovidDeaths$
order by 1,2

-- Looking at Total cases vs Total deaths (DeathRate or DeathPercentage) for Canada

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathRate
From PortfolioProjectSQL..CovidDeaths$
Where location like 'Canada'
-- Where location = 'Canada'
order by 1,2

-- Looking at Total cases vs Population (Prevalence)

Select location, date,  population, total_cases, (total_cases/population)*100 Prevalence
From PortfolioProjectSQL..CovidDeaths$
Where location like 'Canada'
-- Where location = 'Canada'
order by 1,2

-- Looking at Countries with the Highest infection Rate compared to Population

Select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 MaxPrevalencePercentage
From PortfolioProjectSQL..CovidDeaths$
--Where location like 'Canada'
Group by location, population
order by MaxPrevalencePercentage desc

-- Looking at Countries with the highest death count per Population

Select location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectSQL..CovidDeaths$
-- Below Where statement will remove the grouping of countries based on their continent. 
Where continent is not null
Group by location
order by TotalDeathCount desc

-- Looking at the same query as above, but focusing on the continent rather than Location.

Select location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectSQL..CovidDeaths$
Where continent is null
Group by location
order by TotalDeathCount desc

-- Breaking Global Numbers on a daily basis

Select date, sum(New_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(New_deaths as int))/sum(new_cases))*100 as DeathPercentage
From PortfolioProjectSQL..CovidDeaths$
Where continent is not null
Group by date
order by 1,2

-- Breaking down Global Numbers on a Monthly basis

Select Year(date) as Year, Month(date) as Month, sum(New_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(New_deaths as int))/sum(new_cases))*100 as DeathPercentage
From PortfolioProjectSQL..CovidDeaths$
Where continent is not null
Group by Year(date), Month(date)
order by DeathPercentage desc

-- Breaking down Canadian Numbers on a Monthly basis

Select Year(date) as Year, Month(date) as Month, sum(New_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(New_deaths as int))/sum(new_cases))*100 as DeathPercentage
From PortfolioProjectSQL..CovidDeaths$
Where location = 'Canada' and continent is not null
Group by Year(date), Month(date)
order by 1, 2

-- Looking at the other Table with vaccination data
Select * 
From PortfolioProjectSQL..CovidVaccinations$

-- Joining both tables

Select * 
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
order by 1,2,3

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- Looking at a rolling count for the new vaccinations based on the location (Population vs Vaccinations)

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.Location, dea.date) as RollingVaccinationCount
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- Using CTE with above new Column (RollingVaccinationCount) for a new calculation (Percentage of population vaccinated)
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.Location, dea.date) as RollingVaccinationCount
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingVaccinationCount/Population)*100
From PopvsVac

-- Using Temp table with above new Column (RollingVaccinationCount) for a new calculation (Percentage of population vaccinated)

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(250),
Location nvarchar(250),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinationCount numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.Location, dea.date) as RollingVaccinationCount
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingVaccinationCount/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for vissualizations

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.Location, dea.date) as RollingVaccinationCount
From PortfolioProjectSQL..CovidDeaths$ dea
JOIN PortfolioProjectSQL..CovidVaccinations$ Vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *
From PercentPopulationVaccinated