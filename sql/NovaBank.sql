SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT client_ID) AS Total_Clients
FROM dbo.NovaBank;

SELECT
    SUM(CASE WHEN person_emp_length IS NULL THEN 1 ELSE 0 END)
        AS Missing_Employment_Length,
    SUM(CASE WHEN loan_int_rate IS NULL THEN 1 ELSE 0 END)
        AS Missing_Interest_Rate,
    SUM(CASE WHEN other_debt IS NULL THEN 1 ELSE 0 END)
        AS Missing_Other_Debt
FROM dbo.NovaBank;

SELECT
    SUM(CASE
        WHEN person_age < 18 OR person_age > 100
        THEN 1 ELSE 0
    END) AS Invalid_Age,
    SUM(CASE
        WHEN person_emp_length < 0
          OR person_emp_length > person_age 
        THEN 1 ELSE 0
    END) AS Invalid_Employment_Length
FROM dbo.NovaBank;

SELECT
    client_ID,
    person_age,
    person_income,
    person_home_ownership,

    -- EMPLOYMENT LENGTH
    CASE
        WHEN person_emp_length IS NULL THEN NULL
        WHEN person_emp_length < 0 THEN NULL
        WHEN person_age IS NOT NULL
            AND person_emp_length > person_age
        THEN NULL
        ELSE person_emp_length
    END AS person_emp_length,
    employment_type,

    -- LOAN
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_term_months,

    -- TARGET
    loan_status,

    -- CREDIT HISTORY
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    past_delinquencies,
    open_accounts,
    credit_utilization_ratio,

    -- AFFORDABILITY
    loan_to_income_ratio,
    other_debt,
    debt_to_income_ratio,

    -- OTHER BORROWER INFORMATION
    gender,
    marital_status,
    education_level,

    -- GEOGRAPHY
    country,
    state,
    city,
    city_latitude,
    city_longitude

INTO dbo.NovaBank_Clean
FROM dbo.NovaBank;

-- Thêm các cột:
ALTER TABLE [dbo].[NovaBank_Clean]
ADD
    age_band VARCHAR(20),
    employment_length_band VARCHAR(20),
    credit_history_band VARCHAR(20),
    delinquency_band VARCHAR(20),

    income_band VARCHAR(20),
    loan_amount_band VARCHAR(20),
    interest_rate_band VARCHAR(20),

    lti_band VARCHAR(20),
    dti_band VARCHAR(20),

    risk_score INT,
    risk_segment VARCHAR(20);

-- Age band
UPDATE [dbo].[NovaBank_Clean]
SET age_band =
    CASE
        WHEN person_age IS NULL THEN 'Unknown'
        WHEN person_age < 25 THEN '<25'
        WHEN person_age < 35 THEN '25-34'
        WHEN person_age < 45 THEN '35-44'
        WHEN person_age < 55 THEN '45-54'
        ELSE '55+'
    END;

-- Employment Length Band
UPDATE [dbo].[NovaBank_Clean]
SET employment_length_band =
    CASE
        WHEN person_emp_length IS NULL THEN 'Unknown'
        WHEN person_emp_length <= 2 THEN '0-2 years'
        WHEN person_emp_length <= 5 THEN '3-5 years'
        WHEN person_emp_length <= 10 THEN '6-10 years'
        ELSE '11+ years'
    END;

-- Credit History Band
UPDATE [dbo].[NovaBank_Clean]
SET credit_history_band =
    CASE
        WHEN cb_person_cred_hist_length <= 2 THEN '<=2 years'
        WHEN cb_person_cred_hist_length <= 4 THEN '3-4 years'
        WHEN cb_person_cred_hist_length <= 7 THEN '5-7 years'
        WHEN cb_person_cred_hist_length <= 10 THEN '8-10 years'
        ELSE '11+ years'
    END;

-- Past Delinquency Band
UPDATE [dbo].[NovaBank_Clean]
SET delinquency_band =
    CASE
        WHEN past_delinquencies = 0 THEN '0'
        WHEN past_delinquencies = 1 THEN '1'
        WHEN past_delinquencies = 2 THEN '2'
        ELSE '3+'
    END;

-- Income
UPDATE [dbo].[NovaBank_Clean]
SET income_band =
    CASE
        WHEN person_income < 30000 THEN '<30K'
        WHEN person_income < 60000 THEN '30K-60K'
        WHEN person_income < 100000 THEN '60K-100K'
        ELSE '100K+'
    END;

-- Loan Amount
UPDATE [dbo].[NovaBank_Clean]
SET loan_amount_band =
    CASE
        WHEN loan_amnt <= 5000 THEN '<=5K'
        WHEN loan_amnt <= 10000 THEN '5K-10K'
        WHEN loan_amnt <= 15000 THEN '10K-15K'
        WHEN loan_amnt <= 20000 THEN '15K-20K'
        ELSE '>20K'
    END;

-- Interest Rate
UPDATE [dbo].[NovaBank_Clean]
SET interest_rate_band =
    CASE
        WHEN loan_int_rate IS NULL THEN 'Unknown'
        WHEN loan_int_rate <= 8 THEN '<=8%'
        WHEN loan_int_rate <= 10 THEN '8-10%'
        WHEN loan_int_rate <= 12 THEN '10-12%'
        WHEN loan_int_rate <= 15 THEN '12-15%'
        WHEN loan_int_rate <= 20 THEN '15-20%'
        ELSE '>20%'
    END;

-- LTI
UPDATE [dbo].[NovaBank_Clean]
SET lti_band =
    CASE
        WHEN loan_to_income_ratio <= 0.10 THEN '<=10%'
        WHEN loan_to_income_ratio <= 0.20 THEN '10-20%'
        WHEN loan_to_income_ratio <= 0.30 THEN '20-30%'
        WHEN loan_to_income_ratio <= 0.40 THEN '30-40%'
        WHEN loan_to_income_ratio <= 0.50 THEN '40-50%'
        ELSE '>50%'
    END;

-- DTI
UPDATE [dbo].[NovaBank_Clean]
SET dti_band =
    CASE
        WHEN debt_to_income_ratio <= 0.20 THEN '<=20%'
        WHEN debt_to_income_ratio <= 0.40 THEN '20-40%'
        WHEN debt_to_income_ratio <= 0.60 THEN '40-60%'
        WHEN debt_to_income_ratio <= 0.80 THEN '60-80%'
        WHEN debt_to_income_ratio <= 1.00 THEN '80-100%'
        ELSE '>100%'
    END;

-- Loại borrower nào default nhiều hơn?
-- Theo Home Ownership
SELECT
    person_home_ownership,
    COUNT(*) AS Total_Loans,
    SUM(CAST(loan_status AS INT)) AS Default_Loans,
    ROUND(
        100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY person_home_ownership
ORDER BY Default_Rate DESC;

-- Theo độ tuổi
SELECT
    age_band,
    COUNT(*) AS Total_Loans,
    ROUND( 100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY age_band
ORDER BY Default_Rate DESC;

-- Theo thời gian làm việc
SELECT
    employment_length_band,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY employment_length_band
ORDER BY Default_Rate DESC;

-- Loan purpose nào risk cao?
SELECT
    loan_intent,
    COUNT(*) AS Total_Loans,
    SUM(CAST(loan_status AS INT))AS Default_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY loan_intent
ORDER BY Default_Rate DESC;

-- LTI ảnh hưởng default như thế nào?
SELECT
    lti_band,
    COUNT(*) AS Total_Loans,
    ROUND(AVG(loan_to_income_ratio) * 100,2) AS Avg_LTI,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY lti_band
ORDER BY MIN(loan_to_income_ratio) DESC;

-- DTI
SELECT
    dti_band,
    COUNT(*) AS Total_Loans,
    ROUND(AVG(debt_to_income_ratio) * 100,2) AS Avg_DTI,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY dti_band
ORDER BY MIN(debt_to_income_ratio) DESC;

-- Employment Type có khác biệt không?
SELECT
    employment_type,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY employment_type
ORDER BY Default_Rate DESC;

-- Credit history ảnh hưởng thế nào?
-- Previous Default
SELECT
    cb_person_default_on_file,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY cb_person_default_on_file;

-- Credit History Length
SELECT
    credit_history_band,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY credit_history_band
ORDER BY MIN(cb_person_cred_hist_length);

-- Past Delinquencies
SELECT
    delinquency_band,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY delinquency_band
ORDER BY MIN(past_delinquencies);

-- USA, UK, Canada khác nhau không?
SELECT
    country,
    COUNT(*) AS Total_Loans,
    SUM(CAST(loan_status AS INT)) AS Default_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY country
ORDER BY Default_Rate DESC;

--
SELECT
    country,
    state,
    city,
    city_latitude,
    city_longitude,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY
    country,
    state,
    city,
    city_latitude,
    city_longitude
ORDER BY Default_Rate DESC;

-- Loan Grade nào an toàn/rủi ro?
SELECT
    loan_grade,
    COUNT(*) AS Total_Loans,
    ROUND(AVG(loan_int_rate),2) AS Avg_Interest_Rate,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY loan_grade
ORDER BY loan_grade;

-- Loan Term
SELECT
    loan_term_months,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY loan_term_months
ORDER BY loan_term_months;

-- Interest Rate
SELECT
    interest_rate_band,
    COUNT(*) AS Total_Loans,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY interest_rate_band
ORDER BY MIN(loan_int_rate);

-- Tạo nhóm Safe / Risky
-- Risk Score
UPDATE [dbo].[NovaBank_Clean]
SET risk_score =
    -- LOAN GRADE
    CASE
        WHEN loan_grade = 'C' THEN 1
        WHEN loan_grade IN ('D','E','F','G') THEN 3
        ELSE 0
    END
    +
    -- LTI
    CASE
        WHEN loan_to_income_ratio > 0.30 THEN 3
        WHEN loan_to_income_ratio > 0.20 THEN 1
        ELSE 0
    END
    +
    -- DTI
    CASE
        WHEN debt_to_income_ratio > 0.60 THEN 3
        WHEN debt_to_income_ratio > 0.40 THEN 1
        ELSE 0
    END
    +
    -- PREVIOUS DEFAULT
    CASE
        WHEN cb_person_default_on_file = 'Y'
        THEN 2
        ELSE 0
    END
    +
    -- HOME OWNERSHIP
    CASE
        WHEN person_home_ownership IN ('RENT','OTHER')
        THEN 1
        ELSE 0
    END
    +
    -- EMPLOYMENT STABILITY
    CASE
        WHEN person_emp_length IS NULL
          OR person_emp_length <= 2
        THEN 1
        ELSE 0
    END;

-- Chia Risk Segment
UPDATE [dbo].[NovaBank_Clean]
SET risk_segment =
    CASE
        WHEN risk_score <= 2
            THEN 'Low Risk'
        WHEN risk_score <= 5
            THEN 'Medium Risk'
        ELSE 'High Risk'
    END;

SELECT
    risk_segment,
    COUNT(*) AS Total_Loans,
    ROUND(AVG(risk_score),2) AS Avg_Risk_Score,
    ROUND(100.0 * AVG(CAST(loan_status AS FLOAT)),2) AS Default_Rate
FROM [dbo].[NovaBank_Clean]
GROUP BY risk_segment
ORDER BY Avg_Risk_Score;

-- DimBorrowerProfile
CREATE TABLE dbo.DimBorrowerProfile
(BorrowerProfileKey INT IDENTITY(1,1) PRIMARY KEY,
    HomeOwnership VARCHAR(20),
    EmploymentType VARCHAR(30),
    EducationLevel VARCHAR(30),
    Gender VARCHAR(20),
    MaritalStatus VARCHAR(20),
    PreviousDefault CHAR(1),
    AgeBand VARCHAR(20),
    EmploymentLengthBand VARCHAR(20),
    CreditHistoryBand VARCHAR(20),
    DelinquencyBand VARCHAR(20));

INSERT INTO dbo.DimBorrowerProfile
(HomeOwnership,
    EmploymentType,
    EducationLevel,
    Gender,
    MaritalStatus,
    PreviousDefault,
    AgeBand,
    EmploymentLengthBand,
    CreditHistoryBand,
    DelinquencyBand)
SELECT DISTINCT
    person_home_ownership,
    employment_type,
    education_level,
    gender,
    marital_status,
    cb_person_default_on_file,
    age_band,
    employment_length_band,
    credit_history_band,
    delinquency_band
FROM [dbo].[NovaBank_Clean];

-- DimLoanProfile
CREATE TABLE dbo.DimLoanProfile
(LoanProfileKey INT IDENTITY(1,1) PRIMARY KEY,
    LoanIntent VARCHAR(30),
    LoanGrade CHAR(1),
    LoanTermMonths INT);

INSERT INTO dbo.DimLoanProfile
(LoanIntent,
    LoanGrade,
    LoanTermMonths)
SELECT DISTINCT
    loan_intent,
    loan_grade,
    loan_term_months
FROM [dbo].[NovaBank_Clean];

-- DimGeography
CREATE TABLE dbo.DimGeography
(GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
    Country VARCHAR(20),
    State VARCHAR(50),
    City VARCHAR(100),
    Latitude DECIMAL(10,6),
    Longitude DECIMAL(10,6));

INSERT INTO dbo.DimGeography
(Country,
    State,
    City,
    Latitude,
    Longitude)
SELECT DISTINCT
    country,
    state,
    city,
    city_latitude,
    city_longitude
FROM [dbo].[NovaBank_Clean];

-- DimRiskBand
CREATE TABLE dbo.DimRiskBand
(RiskBandKey INT IDENTITY(1,1) PRIMARY KEY,
    IncomeBand VARCHAR(20),
    LoanAmountBand VARCHAR(20),
    InterestRateBand VARCHAR(20),
    LTIBand VARCHAR(20),
    DTIBand VARCHAR(20));

INSERT INTO dbo.DimRiskBand
(IncomeBand,
    LoanAmountBand,
    InterestRateBand,
    LTIBand,
    DTIBand)
SELECT DISTINCT
    income_band,
    loan_amount_band,
    interest_rate_band,
    lti_band,
    dti_band
FROM [dbo].[NovaBank_Clean];

-- DimRiskSegment
CREATE TABLE dbo.DimRiskSegment
(RiskSegmentKey INT PRIMARY KEY,
    RiskSegment VARCHAR(20));

INSERT INTO dbo.DimRiskSegment
VALUES
    (1, 'Low Risk'),
    (2, 'Medium Risk'),
    (3, 'High Risk');

-- FACT TABLE
CREATE TABLE dbo.FactCreditRisk
(LoanKey INT IDENTITY(1,1) PRIMARY KEY,
client_ID VARCHAR(20),

    -- FOREIGN KEYS
    BorrowerProfileKey INT,
    LoanProfileKey INT,
    GeographyKey INT,
    RiskBandKey INT,
    RiskSegmentKey INT,

    -- BORROWER NUMERICAL DATA
    PersonAge INT,
    PersonIncome DECIMAL(18,2),
    EmploymentLength DECIMAL(10,2),

    -- LOAN DATA
    LoanAmount DECIMAL(18,2),
    InterestRate DECIMAL(10,4),

    -- CREDIT / DEBT DATA
    OtherDebt DECIMAL(18,2),
    LoanToIncomeRatio DECIMAL(12,8),
    DebtToIncomeRatio DECIMAL(12,8),

    CreditHistoryLength INT,
    OpenAccounts INT,
    CreditUtilizationRatio DECIMAL(12,8),
    PastDelinquencies INT,

    -- SEGMENT
    RiskScore INT,

    -- TARGET
    DefaultFlag INT);

INSERT INTO dbo.FactCreditRisk
(client_ID,
BorrowerProfileKey,
    LoanProfileKey,
    GeographyKey,
    RiskBandKey,
    RiskSegmentKey,

    PersonAge,
    PersonIncome,
    EmploymentLength,

    LoanAmount,
    InterestRate,

    OtherDebt,
    LoanToIncomeRatio,
    DebtToIncomeRatio,

    CreditHistoryLength,
    OpenAccounts,
    CreditUtilizationRatio,
    PastDelinquencies,

    RiskScore,
    DefaultFlag
)

SELECT
    c.client_ID,

    b.BorrowerProfileKey,
    l.LoanProfileKey,
    g.GeographyKey,
    rb.RiskBandKey,
    rs.RiskSegmentKey,

    c.person_age,
    c.person_income,
    c.person_emp_length,

    c.loan_amnt,
    c.loan_int_rate,

    c.other_debt,
    c.loan_to_income_ratio,
    c.debt_to_income_ratio,

    c.cb_person_cred_hist_length,
    c.open_accounts,
    c.credit_utilization_ratio,
    c.past_delinquencies,

    c.risk_score,
    c.loan_status

FROM dbo.NovaBank_Clean AS c


-- 1. BORROWER DIMENSION
LEFT JOIN dbo.DimBorrowerProfile AS b

    ON ISNULL(c.person_home_ownership, 'Unknown')
       = ISNULL(b.HomeOwnership, 'Unknown')

    AND ISNULL(c.employment_type, 'Unknown')
       = ISNULL(b.EmploymentType, 'Unknown')

    AND ISNULL(c.education_level, 'Unknown')
       = ISNULL(b.EducationLevel, 'Unknown')

    AND ISNULL(c.gender, 'Unknown')
       = ISNULL(b.Gender, 'Unknown')

    AND ISNULL(c.marital_status, 'Unknown')
       = ISNULL(b.MaritalStatus, 'Unknown')

    AND ISNULL(c.cb_person_default_on_file, 'Unknown')
       = ISNULL(b.PreviousDefault, 'Unknown')

    AND ISNULL(c.age_band, 'Unknown')
       = ISNULL(b.AgeBand, 'Unknown')

    AND ISNULL(c.employment_length_band, 'Unknown')
       = ISNULL(b.EmploymentLengthBand, 'Unknown')

    AND ISNULL(c.credit_history_band, 'Unknown')
       = ISNULL(b.CreditHistoryBand, 'Unknown')

    AND ISNULL(c.delinquency_band, 'Unknown')
       = ISNULL(b.DelinquencyBand, 'Unknown')


-- 2. LOAN DIMENSION
LEFT JOIN dbo.DimLoanProfile AS l

    ON ISNULL(c.loan_intent, 'Unknown')
       = ISNULL(l.LoanIntent, 'Unknown')

    AND ISNULL(c.loan_grade, 'Unknown')
       = ISNULL(l.LoanGrade, 'Unknown')

    AND ISNULL(c.loan_term_months, -1)
       = ISNULL(l.LoanTermMonths, -1)


-- 3. GEOGRAPHY DIMENSION
LEFT JOIN dbo.DimGeography AS g

    ON ISNULL(c.country, 'Unknown')
       = ISNULL(g.Country, 'Unknown')

    AND ISNULL(c.state, 'Unknown')
       = ISNULL(g.State, 'Unknown')

    AND ISNULL(c.city, 'Unknown')
       = ISNULL(g.City, 'Unknown')


-- 4. RISK BAND DIMENSION
LEFT JOIN dbo.DimRiskBand AS rb

    ON ISNULL(c.income_band, 'Unknown')
       = ISNULL(rb.IncomeBand, 'Unknown')

    AND ISNULL(c.loan_amount_band, 'Unknown')
       = ISNULL(rb.LoanAmountBand, 'Unknown')

    AND ISNULL(c.interest_rate_band, 'Unknown')
       = ISNULL(rb.InterestRateBand, 'Unknown')

    AND ISNULL(c.lti_band, 'Unknown')
       = ISNULL(rb.LTIBand, 'Unknown')

    AND ISNULL(c.dti_band, 'Unknown')
       = ISNULL(rb.DTIBand, 'Unknown')


-- 5. RISK SEGMENT DIMENSION
LEFT JOIN dbo.DimRiskSegment AS rs

    ON ISNULL(c.risk_segment, 'Unknown')
       = ISNULL(rs.RiskSegment, 'Unknown');

