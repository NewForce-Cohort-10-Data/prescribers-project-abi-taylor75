SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM population;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT *
FROM cbsa;

SELECT *
FROM zip_fips;

-- a. Which prescriber had the highest total number of 
-- claims (totaled over all drugs)? Report the npi and 
-- the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_provider_claims
FROM prescription 
GROUP BY npi, total_claim_count
ORDER BY total_claim_count DESC;

-- b. Repeat the above, but this time report the nppes_provider_first_name,
-- nppes_provider_last_org_name, specialty_description, and the total 
-- number of claims.

SELECT DISTINCT prescriber.npi, prescriber.nppes_provider_first_name, 
prescriber.nppes_provider_last_org_name,
prescriber.specialty_description, SUM(prescription.total_claim_count) AS total_claims 
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE prescription.total_claim_count IS NOT NULL
GROUP BY prescriber.npi, prescriber.nppes_provider_first_name, 
prescriber.nppes_provider_last_org_name,
prescriber.specialty_description
ORDER BY total_claims DESC;

-- a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT DISTINCT prescriber.specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?

SELECT prescriber.specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
ON prescriber.npi = prescription.npi
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag 
ORDER BY total_claims DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber 
-- table that have no associated prescriptions in the prescription table?

SELECT DISTINCT prescriber.specialty_description, SUM(prescription.total_claim_count) AS claims
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE prescription.total_claim_count IS NULL
GROUP BY prescriber.specialty_description;


-- d. Difficult Bonus: Do not attempt until you have solved all other problems! 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?


-- a. Which drug (generic_name) had the highest total drug cost?

SELECT DISTINCT drug_name, SUM(total_drug_cost)
FROM prescription
GROUP BY drug_name
ORDER BY SUM(total_drug_cost) DESC;


-- b. Which drug (generic_name) has the hightest total cost per day? 
-- Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT DISTINCT drug_name, ROUND(AVG(total_drug_cost/total_day_supply), 2) AS cost_per_day
FROM prescription
GROUP BY drug_name
ORDER BY ROUND(AVG(total_drug_cost/total_day_supply), 2) DESC;

-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
-- 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have 
-- antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this.
-- See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name, 
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
	WHEN long_acting_opioid_drug_flag = 'Y' THEN 'Neither'
	WHEN antipsychotic_drug_flag = 'Y' THEN 'Neither'
	END AS drug_type
FROM drug;


-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
-- on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

WITH drug_type AS (
SELECT drug_name,
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
	ELSE 'Neither'
	END AS drug_type
FROM drug)
SELECT drug_type, SUM(total_drug_cost::MONEY) AS total_cost
FROM prescription
INNER JOIN drug_type
ON prescription.drug_name = drug_type.drug_name
WHERE drug_type = 'Opioid' OR drug_type = 'Antibiotic'
GROUP BY drug_type
ORDER BY total_cost DESC;


SELECT DISTINCT drug.drug_name, SUM(prescription.total_drug_cost) AS total_drug_cost,
CASE
	WHEN drug.opioid_drug_flag = 'Y' THEN 'Opioid'
	WHEN drug.antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
	ELSE 'Neither'
	END AS drug_type
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
WHERE drug.opioid_drug_flag = 'Y' OR drug.antibiotic_drug_flag = 'Y'
GROUP BY drug.drug_name, drug_type
ORDER BY SUM(prescription.total_drug_cost) DESC;

-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information
-- for all states, not just Tennessee.

SELECT COUNT(cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN'

-- b. Which cbsa has the largest combined population? Which has the smallest?
-- Report the CBSA name and total population.

SELECT DISTINCT cbsa.cbsa, cbsa.cbsaname, SUM(population)
FROM cbsa
LEFT JOIN population
ON cbsa.fipscounty = population.fipscounty
WHERE population IS NOT NULL
GROUP BY cbsa.cbsaname, cbsa.cbsa
ORDER BY SUM(population) DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? 
-- Report the county name and population.

SELECT DISTINCT population.fipscounty, population.population, fips_county.county
FROM population
FULL JOIN cbsa
ON population.fipscounty = cbsa.fipscounty
FULL JOIN fips_county
ON population.fipscounty = fips_county.fipscounty
WHERE cbsa.cbsa IS NULL AND population.population IS NOT NULL
ORDER BY population DESC;


-- a. Find all rows in the prescription table where total_claims is at least 3000. 
-- Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count 
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE prescription.total_claim_count >= 3000
ORDER BY prescription.total_claim_count;

-- c. Add another column to you answer from the previous part which gives the prescriber
-- first and last name associated with each row.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name
FROM prescription
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
INNER JOIN prescriber 
ON prescription.npi = prescriber.npi
WHERE prescription.total_claim_count >= 3000
ORDER BY prescription.total_claim_count;

-- The goal of this exercise is to generate a full list of all pain management specialists in 
-- Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists 
-- (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
-- where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
-- You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT prescriber.specialty_description, prescriber.nppes_provider_city, prescriber.npi, drug.opioid_drug_flag, drug.drug_name
FROM prescriber
CROSS JOIN drug
WHERE prescriber.specialty_description = 'Pain Management' AND prescriber.nppes_provider_city = 'NASHVILLE' AND drug.opioid_drug_flag = 'Y';


-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether 
-- or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims
-- (total_claim_count).

SELECT prescriber.npi, drug.drug_name, COALESCE(SUM(prescription.total_claim_count), 0) AS total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name
WHERE prescriber.specialty_description = 'Pain Management' AND prescriber.nppes_provider_city = 'NASHVILLE' AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug.drug_name;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
-- Hint - Google the COALESCE function.



















