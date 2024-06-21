/*
Cleaning Data in SQL Queries

Dataset Source: 
Life Expectancy WHO - helps in predicting life expectancy with the help of various factors for a period of 15 years.
The Global Health Observatory (GHO) data repository under World Health Organization (WHO) keeps track of the health status as well as many other related factors for all countries The data-sets are made available to public for the purpose of health data analysis. The data-set related to life expectancy, health factors for 193 countries has been collected from the same WHO data repository website and its corresponding economic data was collected from United Nation website. Although there have been lot of studies undertaken in the past on factors affecting life expectancy considering demographic variables, income composition and mortality rates. It was found that affect of immunization and human development index was not taken into account in the past. 

About the data: 
Each row in the data consists of information about the Country, Continent,Year, Status,Life expectancy,Adult Mortality,infant deaths,Alcohol, GDP in addition to other input parameters.
*/

SELECT *
FROM world_life_expectancy;

-- Standardize Data Format
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Investigate for Duplicate in dataset
SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

-- Identify Duplicate by inserting ROW_NUMBER() for each row consist of (Country + Year)
	-- Display only when ROW_NUMBER() > 1
SELECT *
FROM (
    SELECT Row_Id,
        CONCAT(Country, Year),
        ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS row_num
    FROM world_life_expectancy
    ) AS row_table
WHERE row_num > 1;

-- Delete Duplicate Value
DELETE FROM world_life_expectancy
WHERE Row_Id IN
    (SELECT Row_Id
    FROM (
        SELECT Row_Id,
            CONCAT(Country, Year),
            ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) AS row_num
        FROM world_life_expectancy
        ) AS row_table
WHERE row_num > 1);

-- Rebuilding Missing Value
	-- MIssing Values in Status Field
-- Investigating for Missing Value in Status Field
SELECT * FROM world_life_expectancy.world_life_expectancy
WHERE Status = '';
    
-- Update Status Field
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing';

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed';

-- Rebuilding Missing Value
	-- Insert Calculate Value in Life Expectancy Field
-- Investigating for Missing Value in Lfe Expectancy Field
SELECT Country, Year, `Life Expectancy`
FROM world_life_expectancy;

-- Calculate Missing Value in Life Expectancy
SELECT t1.Country, t1.Year, t1.`Life Expectancy`,
    t2.Country, t2.Year, t2.`Life Expectancy`,
    t3.Country, t3.Year, t3.`Life Expectancy`,
    ROUND((t2.`Life Expectancy` + t3.`Life Expectancy`) / 2,1) AS avgage
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`Life Expectancy` = '';

-- Update Missing Value
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
    ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
    ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life Expectancy` = ROUND((t2.`Life Expectancy` + t3.`Life Expectancy`)/2,1)
WHERE t1.`Life Expectancy` = '';

-- Exploratory Data Analysis
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Explorer World Life Expectancy by Country
SELECT Country, MIN(`Life Expectancy`), MAX(`Life Expectancy`),
    ROUND(MAX(`Life Expectancy`) - MIN(`Life Expectancy`),1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life Expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Life_Increase_15_Years;

-- Explorer Changes in World Life Expectancy by Year.
SELECT Year, ROUND(AVG(`Life Expectancy`),2)
FROM world_life_expectancy
WHERE `Life Expectancy` <> 0
GROUP BY Year
ORDER BY Year;

-- Explorer Life Expectancy Correlation to GDP
SELECT Country, ROUND(AVG(`Life Expectancy`),1) AS Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
AND GDP > 0
ORDER BY GDP;

-- Set Benchmark as $1,500
SELECT
    SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
    AVG(CASE WHEN GDP >= 1500 THEN `Life Expectancy` ELSE NULL END) AS High_GDP_Life_Expectancy,
    SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
    AVG(CASE WHEN GDP <= 1500 THEN `Life Expectancy` ELSE NULL END) AS Low_GDP_Life_Expectancy
FROM world_life_expectancy;

-- Explorer Life Expectancy Correlation to Developed vs Developing Country.
SELECT status, COUNT(DISTINCT Country) AS Country_Count, ROUND(AVG(`Life Expectancy`),1) AS Life_Exp
FROM world_life_expectancy
GROUP BY status;

-- Explorer Life Expectancy Correlation to BMI
SELECT Country, ROUND(AVG(`Life Expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY BMI DESC;

-- Explorer Adult Mortality by Country
SELECT Country, Year, `Life Expectancy`, `Adult Mortality`,
    SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy;
