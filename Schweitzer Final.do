
/*
********************************************************************************
Project Name: Data Management Problem Set #6 dofile -- Final Project
Author: Jason Schweitzer
Preamble:
This do file is for a final project for the Data Management class and aligns with my personal academic interests in student performance.  Data are organized from several
data sets to create a master data set for analysis.

Research questions include the following:
1.) What academic prepardness factors have an effect on students' grade performance at the University?
2.) What demographic information has an effect (or should be controlled for) in examining student grade performance?
3.) How might outcomes differ or vary for those by socioeconomic status (SES)?

The completed data set includes data from the following sources:

1.)  Incoming first-year students at a public research university in the Northeast with their academic preparedness credentials (e.g. HSGPA, SAT scores, etc.) collected from their
	 undergraduate application.  The database stores various data points about an applicant including their converted or weighted HSGPA which is calculated from specific HS courses 
	 and grades they receive.  Applicants enter this information via the SRAR:  Self-Reported Academic Record

2.)  Incoming student demographic information such as race/ethnicity, gender, high school, zipcode, etc. from the university's CRM system

3.)  FAFSA information that includes financial information such as students' expected family contribtuion (EFC), dependency status, adjusted gross income (AGI), household size, etc. 

4.)  College Board Landscape Data: Rutgers subscribes to a paid data service called Landscape that supplies school-specific indices such as college access probability,
     typical education level of the high school, median family income among those in the high school, its geographic setting (e.g. rural, urban, etc.), and an overall percentile score.

5.)  NJ County Data - Per Capital Personal Income by Year
     Per Capita Personal Income for all NJ counties: https://nj.gov/labor/lpa/industry/incpov/incpoverty_index.html
     Data source:  the State of New Jersey Department of Labor and Workforce Development: US Department of Commerce Bureau of Economic Analysis

6.)  NJ County Data -- Residential Housing Units Building Permits
     This data set contains total single- and multi-family residential housing units authorized for building permits for each NJ county.  Data reflect those available from
	 the US Census Bureau, Manufacturing & Construction Division

7.)  Institution Enrollment & Student Performance Data  (term-specific GPAs as well as retention indicator)

********************************************************************************
*/

*** Opening Commands  ***

clear all
set matsize 1000  // Indicates number of variables to be used
version 17     // Declares the Stata version do file was written in

*** Directory  ***

sysdir     //  Lists Stata's system directories

local dir ~/Desktop/DataMgmtFinal  // Local marco with directory path
capture mkdir `dir'     // Make directory
cd `dir'    // Change directory to recently created one above
adopath + `dir'  //  Adds directory to list of possible stored paths

capture log close

log using Schweitzer_DataMgmt.txt, replace   // Create log of session

pwd     // Command to provide present working directory

// findit outreg2
net install outreg2, from (http://repec.org/bocode/o/)

*** Preparing Datasets  ***

// Data set #1: Incoming students with pre-enrollment academic preparedness characteristics (e.g. HSGPA, SAT/ACT scores, etc.)

tempfile gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vRJ05CdMHfbzNR9AKHrzYJ7Hj5swUzxESo6YJn2ZDV7uhydeZe6X9p_K6GbpQSaCw/pub?output=xlsx" `gsheet', replace
import excel using `gsheet', first sheet("data") clear

describe     //  In this data, I'm seeing students' high school GPA, SAT scores, ACT score, an admissions index, HSRANK, and some subject-specific HSGPAs.
summarize    //  The average HSGPA was 3.75 on a 4.5 scale, average SAT scores were 644 for Verbal and 677 for Math with expected values of 800 for maximum of each

recode HSRANK (90/max = 1) (nonm = 0), generate(HS_TOP10) // Generating HSRANK Top 10% dummy variable

tab HSRANK HS_TOP10, mi // Tabulate to check work to make sure recode worked

generate HSRNK_MIS = 1 if HSRANK == .  // Dummy variable for students with missing HS Rank
replace HSRNK_MIS = 0 if HSRNK_MIS == .

tab HSRANK HSRNK_MIS, mi

summarize HSGPA, detail
tab HSGPA, mi

recode HSGPA (min/3.52 = 1) (3.53/3.76 = 2) (3.76/4.02 = 3) (4.03/max = 4), generate(HSGPA_BIN) // Generating a categorical HSGPA variable based on percentiles of variable  25th/50th/75th percentiles based on data

tab HSGPA HSGPA_BIN, mi // Tabulate to check work to make sure recode worked as expected

rename COLLEGE_OF_APPLICATION SCHOOL
destring YR, replace  // Converted YR to numeric for matching later on

generate nCollege = real(SCHOOL)
format nCollege %02.0f

generate SAT_M_10 = SAT_M / 10  // generating for use in regression analysis to interpret as 10 point increase for coefficient
generate SAT_V_10 = SAT_V / 10

save acad.dta, replace

// Data set #2: Student demographic information (e.g. race/ethnicity, gender, high school, etc.)

tempfile gsheet 
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTMTSSQSn5EOcxo3CEX6D_sx9VBtO9Nag9nSSLu6ZVHSx-apC9FsEnKJlhVtUkJ_g/pub?output=xlsx" `gsheet', replace
import excel using `gsheet', first sheet("data") clear

describe     // In this data set, I'm seeing a STEM Major flag and URM indicator along with residency, state, zip, etc.
summarize    // The data consists of 53.6% of students being a STEM major, 50% female, and 20.7% URM
tab STATE, sort     // New Jersey is the most common state with 84% of students having an NJ value
tab RESIDENCY, sort // Similar to above, 84% of students are in-state.  New Jersey students serve as base case.

generate INTL = . // Generate an International student dummy variable from current RESIDENCY variable
replace INTL = 1 if RESIDENCY == "INTL"  // 
replace INTL = 0 if RESIDENCY != "INTL"  // All other values equal 0
tab RESIDENCY INTL, mi // Checking cross-tab to make sure above coding worked as expected

generate OOS = . // Generate an Out-of-State (OOS) student dummy variable from current RESIDENCY variable -- New Jersey becomes "base case" with 84%
replace OOS = 1 if RESIDENCY == "OOS"  // 
replace OOS = 0 if RESIDENCY != "OOS"  // All other values equal 0
tab RESIDENCY OOS, mi // Checking cross-tab to make sure above coding worked as expected

tab COUNTY  // Display county values for future join re-code

destring YR, replace  // Converted YR to numeric for matching later on

save demo.dta, replace

// Data set #3: FAFSA information

tempfile FAFSAsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vQRMpzsvK9QIFRIqQ7Bp6Yb9af1aVWkIoiCEjP6RnQgel50WOa-380k5d-LGe3wdQ/pub?output=xlsx" `FAFSAsheet', replace
import excel using `FAFSAsheet', first sheet("data") clear

summarize
describe
tab OLDEFC  // No obs -- drop below
rename COSTOFATTENDANCE COA

drop OLDEFC

//  Create log variable transformations for regressions

foreach logvar in EFC HOUSEHOLDAGI {
generate LN`logvar' = ln(`logvar')	
}

destring YR, replace  // Converted YR to numeric for matching later on

save fafsa.dta, replace

// Data set #4: College Board Landscape Data regarding high school specific information

tempfile HSsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vR45EjcDtQsGsSgdW28P9gnEX7g0M-3XcU_6pCsWXi6uIuDYLVPhLifj_mSBr5xmQ/pub?output=xlsx" `HSsheet', replace
import excel using `HSsheet', first sheet("data") clear

describe
tab RURAL

// Rename variables for easier analysis
rename A_HS_COLLEGE_ACCESS HS_ACCESS
rename A_HS_EDUC_PTILE HS_ED_LVL
rename A_HS_MEDFAMINC_PTILE HS_MED_INC
rename A_HS_OVERALL_PTILE HS_OVERALL_SCORE
rename RURAL LOCALE

tab LOCALE // 12 categories -- want to recode for better analysis
gen AREA = regexs(0) if regexm(LOCALE, "[a-zA-Z]+")

encode AREA, gen(nArea)
codebook nArea

save hslandscape.dta, replace

// Data set #5

tempfile Ctysheet
copy "https://nj.gov/labor/lpa/industry/incpov/pcicnty.xls" `Ctysheet', replace
import excel using `Ctysheet', cellrange(A6:BA28) firstrow case(preserve) clear

describe

// After reviewing the data, the year column labels did not come in.  I searched the internet and found that Stata doesn't like numeric variable names.  The same internet search yielded
// this solution: https://blog.stata.com/2012/06/25/using-import-excel-with-real-world-data/

foreach var of varlist _all {
	local label : variable label `var'
	local new_name = lower(strtoname("`label'"))
	rename `var' `new_name'
}

describe // Checking to make sure above code worked as expected

// Need to create a matching ID field in new data for each NJ county

generate COUNTY = "" // Generate a NJ County ID variable for merge
replace COUNTY = "AT" if geoname == "Atlantic, NJ"
replace COUNTY = "BE" if geoname == "Bergen, NJ"
replace COUNTY = "BU" if geoname == "Burlington, NJ"
replace COUNTY = "CA" if geoname == "Camden, NJ"
replace COUNTY = "CM" if geoname == "Cape May, NJ"
replace COUNTY = "CU" if geoname == "Cumberland, NJ"
replace COUNTY = "EX" if geoname == "Essex, NJ"
replace COUNTY = "GL" if geoname == "Gloucester, NJ"
replace COUNTY = "HD" if geoname == "Hudson, NJ"
replace COUNTY = "HN" if geoname == "Hunterdon, NJ"
replace COUNTY = "ME" if geoname == "Mercer, NJ"
replace COUNTY = "MI" if geoname == "Middlesex, NJ"
replace COUNTY = "MO" if geoname == "Monmouth, NJ"
replace COUNTY = "MR" if geoname == "Morris, NJ"
replace COUNTY = "OC" if geoname == "Ocean, NJ"
replace COUNTY = "PA" if geoname == "Passaic, NJ"
replace COUNTY = "SA" if geoname == "Salem, NJ"
replace COUNTY = "SO" if geoname == "Somerset, NJ"
replace COUNTY = "SX" if geoname == "Sussex, NJ"
replace COUNTY = "UN" if geoname == "Union, NJ"
replace COUNTY = "WA" if geoname == "Warren, NJ"
replace COUNTY = "NJ" if geoname == "New Jersey"
label variable COUNTY "NJ County"

list geoname COUNTY // Checking to make sure above coding worked as expected

keep geofips geoname COUNTY _201*

save county.dta, replace

reshape long _, i(COUNTY) j(year)

rename _ percap  // Renamed variable name to give it meaning
generate YR = year + 2  // Generating new YR variable two years forward for the merge for applicable data.  For example, when a student begins college during the Fall 2021 semester,
// their filed FAFSA is for the "prior prior" year.  Fall 2021 semester = Fall 2020 tax filing  = 2019 data
// https://www.nextstepu.com/What-is-Prior-Prior-Year.art#.YhE0aRZ7lPY
/* Prior-Prior year is a new policy implemented in 2016 that allows students and families to file the FAFSA
using tax information from two years prior. For example, a high school student looking to attend college in 
Fall 2017 would file the FAFSA using taxes from 2015 rather than 2016. Hence the name "Prior-Prior." 
Also, using the Prior-Prior Year system allows students and families to apply for financial aid
 in October rather than waiting until January.
 Will document in paper/analysis the meaning and interpretation of the variables
 */

save countylong.dta, replace

// Data set #6

tempfile Permsheet
copy "https://nj.gov/labor/lpa/industry/bp/hist10/county10to18.xlsx" `Permsheet', replace
import excel using `Permsheet', cellrange(A3:K27) firstrow case(preserve) clear

describe

// After reviewing the data and similar to the previous data set, the year column labels did not come in.  They come in under Excel column alphas.  I searched the internet and found that Stata doesn't like numeric variable names.  The same internet search yielded
// this solution: https://blog.stata.com/2012/06/25/using-import-excel-with-real-world-data/

foreach var of varlist _all {
	local label : variable label `var'
	local new_name = lower(strtoname("`label'"))
	rename `var' `new_name'
}

describe  // Checking data to make sure the above foreach work as intended
// There are two null rows that need removal

rename (_*) (y*)
describe
rename county geoname // Renaming county variable so newly created field matches previous one and one for upcoming merge
drop total_

// Need to create a matching ID field in new data for each county

generate COUNTY = "" // Generate a NJ County ID variable for merge
replace COUNTY = "AT" if geoname == "Atlantic County"
replace COUNTY = "BE" if geoname == "Bergen County"
replace COUNTY = "BU" if geoname == "Burlington County"
replace COUNTY = "CA" if geoname == "Camden County"
replace COUNTY = "CM" if geoname == "Cape May County"
replace COUNTY = "CU" if geoname == "Cumberland County"
replace COUNTY = "EX" if geoname == "Essex County"
replace COUNTY = "GL" if geoname == "Gloucester County"
replace COUNTY = "HD" if geoname == "Hudson County"
replace COUNTY = "HN" if geoname == "Hunterdon County"
replace COUNTY = "ME" if geoname == "Mercer County"
replace COUNTY = "MI" if geoname == "Middlesex County"
replace COUNTY = "MO" if geoname == "Monmouth County"
replace COUNTY = "MR" if geoname == "Morris County"
replace COUNTY = "OC" if geoname == "Ocean County"
replace COUNTY = "PA" if geoname == "Passaic County"
replace COUNTY = "SA" if geoname == "Salem County"
replace COUNTY = "SO" if geoname == "Somerset County"
replace COUNTY = "SX" if geoname == "Sussex County"
replace COUNTY = "UN" if geoname == "Union County"
replace COUNTY = "WA" if geoname == "Warren County"
replace COUNTY = "NJ" if geoname == "New Jersey"
label variable COUNTY "NJ County"

list geoname COUNTY // Checking to make sure above coding worked as expected

drop if geoname == ""
list // didn't drop both observations
drop if y2010 == .
describe // data set now expected

reshape long y, i(COUNTY) j(year)

rename y ctypermits  // Renamed variable name to give it meaning
generate YR = year + 3  // Generating new YR variable three years forward for the merge for applicable data.
// Will document in paper/analysis the meaning and interpretation of the variables.  Three years after permit issues accounts for construction time of new properties

save countylongpermit.dta, replace

// Data set #7

tempfile Enrollsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTUQKb2BKqam66wfdO-sOPmNS2D6fDPprs9tjYid3fD8ZMlc6qaC-QecWgpCA0Y4g/pub?output=xlsx" `Enrollsheet', replace
import excel using `Enrollsheet', first sheet("data") clear

destring YR, replace  // Converted YR to numeric for match
replace Second_Term_Status = 3 if Second_Term_Status == .

//  Shorten current variable names and create variable labels for easier reference later on and use during analysis

rename Enrolled TERM1
rename First_Term_Status TERM1Stat
rename First_Term_Credits TERM1Cr
rename First_Term_GPA TERM1GPA
rename Second_Term_Status TERM2Stat
rename Second_Term_Credits TERM2Cr
rename First_Year_GPA FY_GPA
rename Sophomore_Retention TERM3

save enroll, replace


***  Merging  ***

use acad.dta, clear

merge 1:1 ID using demo, generate(_mergeda) //  Academic file becomes using -- 28,006 records

merge 1:1 ID using fafsa, generate(_mergesf)
keep if inlist(_mergesf,1,3)  //   Keep matched records but also unmatched from master (incoming students without a FAFSA match)

merge m:1 CEEB using hslandscape, generate(_mergeshs)
keep if inlist(_mergeshs,1,3)  // Keep matched records as well as unmatched from master.  There were 3 high schools not listed in CB file. Investigated and OK

merge m:1 COUNTY YR using countylong, generate(_mergecty)
keep if inlist(_mergecty,1,3) // "NJ" placeholder accounts for 10.  The others are a single occurence of each NJ county for each year.  OK to discard.

merge m:1 COUNTY YR using countylongpermit, generate(_mergectyp)
keep if inlist(_mergecty,1,3)  // Manual review cases -- they appear to be in-state students attending an OOO high schools

merge 1:1 ID using enroll, generate(_mergeout)
keep if inlist(_mergeout, 3)  // Data set includes 28,006 original student records for analysis


tab NUM  // All values are 1 -- file was created with a duplicate student indicator
drop _merge* NUM COLLEGE_OF_APPLICATION SCHOOLCODE 

save master, replace

*** Variable labels  ***

label variable YR "Application Year"
label variable ACT_SCORE "ACT Score"
label variable HSGPA "High School GPA"
label variable SAT_M "SAT Math"
label variable SAT_V "SAT Verbal"
label variable SAT_M_10 "SAT Math / 10"
label variable SAT_V_10 "SAT Verbal / 10"
label variable SAT_TOTAL "SAT Total"
label variable HSRANK "High School Rank"
label variable HS_TOP10 "High School Rank Top 10%"
label variable HSRNK_MIS "High School Rank Missing"
label variable HSGPA_BIN "High School GPA Quartile"
label variable SCHOOL "College of Application"
label variable ADM_INDX "Admissions Index"
label variable EN_CONV_GPA "High School English GPA"
label variable MT_CONV_GPA "High School Math GPA"
label variable SS_CONV_GPA "High School Social Studies GPA"
label variable NS_CONV_GPA "High School Science GPA"
label variable nCollege "School of Application"

label variable STEM_IND "Academic Interest in STEM"
label variable FEMALE "Female"
label variable RESIDENCY "Residency"
label variable INTL "International Student"
label variable OOS "Out-of-State Student"
label variable STATE "State"
label variable COUNTY "New Jersey County of Residence"
label variable CEEB "High School CEEB"
label variable HS_NAME "High School Name"
label variable URM_IND "Underrepresented Minority"
label variable ETHNICITY "Race/Ethnicity"
label variable ZIP "Zipcode"

label variable EFC "Expected Family Contribution"
label variable HOUSEHOLDAGI "Student's Household Adjusted Gross Income"
label variable DEPSTAT "Dependency Status"
label variable NJEI "New Jersey Eligibility Index"
label variable SZ_HSD  "Size of Student's Household"
label variable NUMCOL_P "Number of persons in College"
label variable COA "Cost of Attendance"
label variable LNEFC "Log (Expected Family Contribution)"
label variable LNHOUSEHOLDAGI "Log (Student's Household Adjusted Gross Income)"

label variable HS_ACCESS "High School College Attedance Indicator"
label variable HS_ED_LVL "High School Typical Education Level Indicator"
label variable HS_MED_INC "High School Median Family Income Indicator"
label variable HS_OVERALL_SCORE "High School Overall Indicator"
label variable LOCALE "High School Specific Geographic Area"
label variable AREA "High School Geographic Area"

label variable percap "New Jersey County Per Capita Personal Income Prior-Prior Year"
label variable ctypermits "New Jersey County Residential Housing Permits Three Years Prior"

label variable TERM1 "First Term Enrolled"
label variable TERM1Stat "First Term Attendance Status"
label variable TERM1Cr "First Term Credits Attempted"
label variable TERM1GPA "First Term Grade Point Average"
label variable TERM2Stat "Second Term Attendance Status"
label variable TERM2Cr "Second Term Credits Attempted"
label variable FY_GPA "First Year Grade Point Average"
label variable TERM3 "First to Second Year Retention"

*** Value labels  ***

label define college_cd 01 "SAS" 07 "MGSA" 11 "SEBS" 14 "SOE" 25 "NURS-NK" 30 "PHARM" 33 "RBS-NB" 77 "NURS-NB"
label values nCollege college_cd

label define att_stat 1 "Full-time" 2 "Part-time" 3 "No longer enrolled"
label values TERM1Stat TERM2Stat att_stat

label define URM 1 "URM" 0 "Not URM"
label values URM_IND URM

save master, replace

***  Descriptive Statistics  ***

tab TERM1, mi // All students enrolled their first term -- this is as expected

preserve
collapse (count) ID, by(YR) // Cohort counts by year from 2018 to 2021
list
restore

preserve
collapse HSGPA SAT_V SAT_M, by(YR) // Displays average (default) statistics on HSGPA and SAT scores for the four cohorts
list
restore

preserve
collapse (median) HSGPA SAT_V SAT_M, by(SCHOOL YR) // Displays median statistics on HSGPA and SAT scores for each academic unit by year.
list
restore

tab URM_IND, mi  // 20.7% of the university sample are underrepresented minorities

tab ETHNICITY, mi // 8.5% are African American, 11.5% Hispanic, 45.5% Asian, 32% Caucasian

tab STEM_IND, mi // 54% of students are interested in a STEM major

tab FEMALE, mi // 50% of students are female

tab nArea, mi  // 76% of students come from the suburbs, 8.4% rural, 6% city, 0.6% town wiht 8.8% missing

preserve
collapse HOUSEHOLDAGI, by(YR) // Displays average household AGIs for the four cohorts.  Range from $129,848 in 2018 to $143,133 in 2020.
list
restore

outreg2 * using SummaryStats.xls, replace sum(log) keep(FY_GPA HSGPA SAT_M SAT_V HS_TOP10 ///
HSRNK_MIS FEMALE URM_IND STEM_IND)

*** Graphs  ***

graph matrix HSGPA SAT_V SAT_M FY_GPA, half mcolor(%5) ///
name(matrix1, replace)
graph export Scatter1.eps, replace  //  EPS format for better resolution
// Quick look reveals positive relationships between First Year GPA and independent vars

graph matrix HSGPA SAT_V SAT_M TERM1GPA, half mcolor(%5) ///
name(matrix2, replace)
graph export Scatter2.eps, replace  //  EPS format for better resolution
// Quick look reveals similar as above: positive relationships between First Term GPA and independent vars

pwcorr FY_GPA HSGPA SAT_M SAT_V, sig star(0.05)
// Significant bivariate relationships found

graph box SAT_V SAT_M, ///
name(box1, replace)       
graph export SATBox.eps, replace
// I wanted to get a sense of SAT score distribution.  Avg. SAT Math score slightly higher (675ish vs. 650ish for Verbal) with middle 50%tile shown.  There are a few outliers for each variable on the lower end.

graph bar FY_GPA, over(HSGPA_BIN) ///
name(bar1, replace)
graph export HSGPABinbar.eps, replace
// This graph shows average First Year GPA bin by HSGPA percentile bins.  It's showing students who perform better in HS do, on average, perform better in college their first year.

graph hbar FY_GPA, over(RESIDENCY) blabel(bar, format(%4.3f)) ytitle("Average First-Year GPA") ///
name(hbarRES, replace)
graph export REShbar.eps, replace
//  In reviewing by residency, international students seem to perform the "worst" with the lowest average FYGPA of 3.079.

graph hbar FY_GPA, over(URM_IND) blabel(bar, format(%4.3f)) ytitle("Average First-Year GPA") ///
name(hbarURM, replace)
graph export URMbar.eps, replace
//  In reviewing by URM status, underrepresented minority students seem to perform lower than non-URMs with an avg. FYGPA of 3.132.

preserve
collapse (mean) FY_GPA if YR < 2021, by (YR nCollege)
bytwoway (line FY_GPA YR),  by(nCollege) aes(color)  colors("204 0 51" "95 106 114" "0 0 0" "240 230 192" "22 122 88" "102 36 0" "204 198 173" "0 179 162") ///
legend(col(5) size(small) symxsize(*0.5) region(fcolor(gs15)))  ///
ytitle("") ///
ylabel(2.75 (0.25) 3.75) ///
xtitle("Fall Cohort Year") ///
xlabel (2018 (1) 2020) ///
name(line1, replace) ///
title("Rutgers–New Brunswick Incoming First-Year Students") ///
subtitle("Average First Year GPA Trends") ///
note("Source: Data extracted from NJAS & SRDB.")

graph export line.eps, replace
// I wanted to review First-Year GPA trends over time for each academic unit.  Most academic units saw continual increases in their students' FYGPA with the exception of NURS-NB and MGSA.

restore

preserve
collapse (mean) TERM1GPA, by (YR nCollege)
bytwoway (line TERM1GPA YR),  by(nCollege) aes(color)  colors("204 0 51" "95 106 114" "0 0 0" "240 230 192" "22 122 88" "102 36 0" "204 198 173" "0 179 162") ///
legend(col(5) size(small) symxsize(*0.5) region(fcolor(gs15)))  ///
ytitle("") ///
ylabel(2.75 (0.25) 3.75) ///
xtitle("Fall Cohort Year") ///
xlabel (2018 (1) 2021) ///
name(line1, replace) ///
title("Rutgers–New Brunswick Incoming First-Year Students") ///
subtitle("Average First Term GPA Trends") ///
note("Source: Data extracted from NJAS & SRDB.")

graph export line2.eps, replace
/* In reviewing First Term GPA, students from each academic school experiences a "bump up" for the fall 2020 semester.  Perhaps this is due to the institutional grading policy established
     around COVID when the college went all remote and students had Pass/No Credit option.
     Reference: https://nbprovost.rutgers.edu/guidance-faq
*/

restore

foreach v of varlist HSGPA TERM1GPA FY_GPA EFC HOUSEHOLDAGI LNEFC LNHOUSEHOLDAGI {
	histogram `v', normal name(hist`v', replace)
	graph export hist`v'.eps, replace
}

// Quick histograms of variables reveal log of EFC and AGI are more normally distributed

twoway (scatter TERM1GPA SAT_M, color(%15 "204 0 51") lcolor(black)) ///
(scatter TERM1GPA SAT_V, color(%5 "95 106 114") lcolor(black)), ///
legend(order(1 "SAT Math" 2 "SAT Verbal")) ///
name(scatter1, replace)
graph export TERM1GPASAT.eps, replace
// SAT Verbal looks like it's more related to First Term GPA than SAT Math.

graph dot (p25) HSGPA (p75) HSGPA if YR < 2021, over(nCollege) ///
title("Incoming First-Year Students") ///
subtitle("Middle 50% HSGPA") ///
legend(label(1 "25th percentile") label(2 "75th percentile")) ///
name(dot1, replace)
graph export dot1.eps, replace
// Reviewing middle 50% for each unit: MGSA and SEBS look like they have the widest range with PHARM the narrowest.

graph dot (p25) FY_GPA (p75) FY_GPA if YR < 2021, over(nCollege) ///
title("Incoming First-Year Students") ///
subtitle("Middle 50% First Year GPA") ///
legend(label(1 "25th percentile") label(2 "75th percentile")) ///
name(dot2, replace)
graph export dot2.eps, replace

// Reviewing middle 50% of first year GPA for each unit: SOE has the widest range with NURS-NK and NURS-NB the narrowest.

scatter FY_GPA HSGPA || lfit FY_GPA HSGPA ||, by(SCHOOL, total row(2)) ///
name(scatterfit1, replace)
graph export scatterunit.eps, replace
// Each unit shows a positive relationship between HSGPA and FYGPA with slight differences in effect (slope of line).

twoway lfitci FY_GPA HSGPA, name(twoway1, replace)
graph export linear1.eps, replace
// Overall, there is a positive relationship between HSGPA and FYGPA.

preserve

set seed 2038947  // Setting seed to be able to reproduce random sample below.

sample 15

twoway lfitci FY_GPA HSGPA, name(twowaysamp, replace)
graph export linear2.eps, replace
// Same graph as above but taking a random sample of 15% of data that shows a wider 95% confidence interval.

restore

*** Regressions  ***

// Run entire section in one shot due to local declared macros

// Declare macros with independent variable sets for models
local HSAcademics HSGPA SAT_M_10 SAT_V_10
local Demographics FEMALE URM_IND STEM_IND
local Residency OOS INTL
local FinAid LNHOUSEHOLDAGI LNEFC
local CB_HS HS_ACCESS HS_ED_LVL HS_OVERALL_SCORE i.nArea
local County percap ctypermits

regress FY_GPA HSGPA, vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel1, replace)
estimates store Model_1

regress FY_GPA `HSAcademics', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel2, replace)
estimates store Model_2

regress FY_GPA `HSAcademics' `Demographics', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel3, replace)
estimates store Model_3

regress FY_GPA `HSAcademics' `Demographics' `Residency', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel4, replace)
estimates store Model_4

regress FY_GPA `HSAcademics' `Demographics' `Residency' LNHOUSEHOLDAGI, vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel5, replace)
estimates store Model_5

regress FY_GPA `HSAcademics' `Demographics' `Residency' `FinAid', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel6, replace)
estimates store Model_6

regress FY_GPA `HSAcademics' `Demographics' `Residency' `FinAid' `CB_HS', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel7, replace)
estimates store Model_7

regress FY_GPA `HSAcademics' `Demographics' `Residency' `FinAid' `CB_HS' `County', vce(robust)
rvfplot, yline(0) ///
name(rvfplotModel8, replace)
estimates store Model_8

* Regression Table using esttab
esttab Model_* using "Regression_Output.csv" , replace order(_cons) ///
	mtitle label stats(rss df_r r2 F N) ///
	cells(b (fmt(3) star) se(par fmt(3))) varwidth(40) ///
	title("Table 1: Determinants of First-Year College GPA")  

exit
