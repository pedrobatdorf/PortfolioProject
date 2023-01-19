
-- Cleaning Data in SQL Queries
-- Nashville Housing Data for Data Cleaning

SELECT *
FROM PortfolioProject.. NashvilleHousing


---------------------------------------------------------------------------

-- Standardize Date Format --

--(
-- In the SaleDate Column, it has time (00:00:00) in the end and it serves no purpose, so I am taking it off.
SELECT SaleDate, CONVERT(Date,SaleDate) -- This is what we want it to look like.
FROM PortfolioProject.. NashvilleHousing -- ***IT DID NOT WORK***

UPDATE NashvilleHousing  -- It made the update but it's still showing the time (00:00:00.000)
SET SaleDate = CONVERT(Date,SaleDate)
--)

-- Query above did not work for me.
-- Query below worked for me!

--(
ALTER TABLE NashvilleHousing -- We Can do ALTER TABLE
ADD SaleDateConverted Date; -- Add This column and then update below

UPDATE NashvilleHousing -- Update
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted, CONVERT(Date,SaleDate) -- This is what we want it to look like, it shows no time.
FROM PortfolioProject.. NashvilleHousing 
-- Make sure to update SaleDateConverted to SaleDate
--)


---------------------------------------------------------------------------

-- Populate Property Address date --

-- Lots of PropertyAddress are NULL values
-- Each PropertyAddress as a unique ParcelID
-- There is some duplicate ParcelID, one with a PropertyAddress and one with a NULL value for PropertyAddress.
-- So if a ParcelID is populating an address and the duplicate is not, lets populated with the ParcelID that does to get rid of the NULL value.

SELECT PropertyAddress
FROM PortfolioProject.. NashvilleHousing
WHERE PropertyAddress IS NULL -- Many PropertyAddress have NULL value


SELECT *
FROM PortfolioProject.. NashvilleHousing
ORDER BY ParcelID -- I found mutiple duplicate ParcelID.


SELECT a.ParcelID, a.PropertyAddress, a.ParcelID, b.PropertyAddress
FROM PortfolioProject.. NashvilleHousing a 
JOIN PortfolioProject.. NashvilleHousing b
	ON a.ParcelID = b.ParcelID -- I joined the same exact table to it self (Self Join) where the ParcelID is the same but have different UniqueID.
	AND a.[UniqueID ] <> b.[UniqueID ] -- There is no duplicate UniqueID.
WHERE a.PropertyAddress IS NULL -- It has an adress for all NULL PropertyAddress

-- Use an ISNULL and insert b.PropertyAddress into a.PropertyAddress
--(
SELECT a.ParcelID, a.PropertyAddress, a.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress )
FROM PortfolioProject.. NashvilleHousing a 
JOIN PortfolioProject.. NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress IS NULL 

UPDATE a -- Must use it ALIAS
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress )
FROM PortfolioProject.. NashvilleHousing a 
JOIN PortfolioProject.. NashvilleHousing b
	ON a.ParcelID = b.ParcelID 
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL 
-- It worked; now none has NULL in there.
--)


---------------------------------------------------------------------------

-- Breaking out Address into Indvidual columns (Adress, City, State)

SELECT PropertyAddress
FROM PortfolioProject.. NashvilleHousing


--SubStrings
-- Looking at PropertyAddress
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress )-1) as Adress -- Specify what we are looking for
 --CHARINDEX(',', PropertyAddress ) -- -1 deletes the comma
FROM PortfolioProject.. NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress )-1) as Adress 
 ,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress )+1, LEN(PropertyAddress))  as City -- Where does it have to go to.
FROM PortfolioProject.. NashvilleHousing -- +1 Takes out the comma


-- It's not possible to seperate 2 values from 1 colms without creating 2 additional coloumns
-- I created 2 more columns

ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress Nvarchar(255); 

UPDATE NashvilleHousing -- Update
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress )-1)


ALTER TABLE NashvilleHousing 
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing -- Update
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress )+1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.. NashvilleHousing


---- Now looking at OwnerAdress, I need to split Adress, City, and State.
-- I am not using substrings
-- I am using PARSENAME

SELECT OwnerAddress
FROM PortfolioProject.. NashvilleHousing


SELECT
PARSENAME (OwnerAddress,1)
FROM PortfolioProject.. NashvilleHousing

-- PARSENAME only replaces periods not commas
-- I replaced the periods with commas

SELECT
PARSENAME (REPLACE(OwnerAddress,',','.'), 3) AS Address
, PARSENAME (REPLACE(OwnerAddress,',','.'), 2) AS City
, PARSENAME (REPLACE(OwnerAddress,',','.'), 1) AS State
FROM PortfolioProject.. NashvilleHousing

-- Now I need to add columns and values.

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress Nvarchar(255); 

UPDATE NashvilleHousing -- Update
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress,',','.'), 3)


ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing -- Update
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashvilleHousing 
ADD OwnerSplitState Nvarchar(255); 

UPDATE NashvilleHousing -- Update
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress,',','.'), 1)

SELECT *
FROM PortfolioProject.. NashvilleHousing





---------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field. 

SELECT DISTINCT (SoldAsVacant), COUNT (SoldAsVacant)
FROM PortfolioProject.. NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
 , CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END
FROM PortfolioProject.. NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'NO'
		ELSE SoldAsVacant
		END

---------------------------------------------------------------------------

-- Remove Duplicates
-- USE CTE
WITH RowNumCTE AS(
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

FROM PortfolioProject.. NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

Select *
From PortfolioProject.dbo.NashvilleHousing



---------------------------------------------------------------------------

-- Delete unused columns

SELECT *
FROM PortfolioProject.. NashvilleHousing

ALTER TABLE PortfolioProject.. NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE PortfolioProject.. NashvilleHousing
DROP COLUMN SaleDate; -- Forgot to delete the SaleDate column