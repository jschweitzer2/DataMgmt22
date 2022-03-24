clear all
// change dir

version 17     // Declares the Stata version do file was written in
sysdir     //  Lists Stata's system directories

capture mkdir ~/Desktop/DataMgmtPS4     // Make directory
// adopath + ~/Desktop/DataMgmt  holding line for now since no installed Stata commands are needed

cd ~/Desktop/DataMgmtPS4    // Change directory to recently created one above

capture log close

log using Schweitzer_PS4.txt, replace   // Create log of session

pwd     // Command to provide present working directory


/*
******************************************************
Project Name: Data Management Problem Set #4 dofile -- First Draft of Final Project
Jason Schweitzer
Preamble:

I began to understand the impact and relationships between pre-enrollment student characteristics on student performance through descriptive statistics and initial regressions.

Research questions include the following:
1.) What factors have an effect on students' grade performance at the University?
2.) What factors have an effect on early retention progress at the University?

this file pulls down six data sets:
1.) a list of incoming first-year students at a public research university in the Northeast with their academic preparedness credentials (e.g. HSGPA, SAT scores, etc.) collected from their
undergraduate application.  The database stores various data points about an applicant including their converted or weighted HSGPA which is calculated from specific HS courses and grades they receive.  Applicants enter this information via the SRAR:  Self-Reported Academic Record and
2.) incoming student demographic information such as race/ethnicity, gender, high school, zipcode, etc. from the university's CRM system
3.)  FAFSA information that includes financial information such as students' expected family contribtuion (EFC), dependency status, AGI, household size, etc. 
4.)  College Board Landscape Data: Rutgers subscribes to a paid data service called Landscape that supplies us with school-specific indices such as college access probability,
typical education level of the high school, median family income among those in the high school, its geographic setting (e.g. rural, urban, etc.), and an overall percentile score.
5.)  NJ County Data - Per Capital Personal Income by Year
     Per Capita Personal Income for all NJ counties: https://nj.gov/labor/lpa/industry/incpov/incpoverty_index.html
     Data source:  the State of New Jersey Department of Labor and Workforce Development: US Department of Commerce Bureau of Economic Analysis

6.)  NJ County Data -- Residential Housing Units Building Permits
     This data set contains total single- and multi-family residential housing units authorized for building permits for each NJ county.  Data reflect those available from the US Census Bureau, Manufacturing & Construction Division

7.)  Institution Enrollment & Student Performance Data  (term-specific GPAs as well as retention indicator)

******************************************************
*/

set matsize 800     // Sets the maximum number of variables to specific amount, default is 400

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vRJ05CdMHfbzNR9AKHrzYJ7Hj5swUzxESo6YJn2ZDV7uhydeZe6X9p_K6GbpQSaCw/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     //  In this data, I'm seeing students' high school GPA, SAT scores, ACT score, an admissions index, HSRANK, and some subject-specific HSGPAs.
summarize    //  The average HSGPA was 3.75 on a 4.5 scale, average SAT scores were 644 for Verbal and 677 for Math with expected values of 800 for maximum of each.
tab YR       //  The file contains incoming students from the years 2018 to 2021 ranging from the low in 2020 of 6,553 to the high of 7,310 in 2019.


recode HSRANK (90/max = 1) (nonm = 0), generate(HS_TOP10) // Generating HSRANK Top 10% dummy variable

tab HSRANK HS_TOP10, mi // Tabulate to check work to make sure recode worked as expected

generate HSRNK_MIS = 1 if HSRANK == .  // Dummy variable for students with missing HS Rank
replace HSRNK_MIS = 0 if HSRNK_MIS == .

tab HSRANK HSRNK_MIS, mi

summarize HSGPA, detail
tab HSGPA, mi

recode HSGPA (min/3.52 = 1) (3.53/3.76 = 2) (3.76/4.02 = 3) (4.03/max = 4), generate(HSGPA_BIN) // Generating a categorical HSGPA variable based on percentiles of variable  25th/50th/75th percentiles based on data

tab HSGPA HSGPA_BIN, mi // Tabulate to check work to make sure recode worked as expected

rename COLLEGE_OF_APPLICATION SCHOOL

// Label variables
label variable YR "Application Year"
label variable ACT_SCORE "ACT Score"
label variable HSGPA "High School GPA"
label variable SAT_M "SAT Math"
label variable SAT_V "SAT Verbal"
label variable SAT_TOTAL "SAT Total"
label variable HSRANK "High School Rank"
label variable HS_TOP10 "High School Rank Top 10%"
label variable HSRNK_MIS "High School Rank Missing"
label variable HSGPA_BIN "High School GPA Quartile"
label variable SCHOOL "College of Application"

/*
generate nYR = real(YR)
format nYR %4.0f
label variable nYR "Year"
*/

generate nCollege = real(SCHOOL)
format nCollege %02.0f

label variable nCollege "School of Application"

// label SCHOOL variable values
label define college_cd 01 "SAS" 07 "MGSA" 11 "SEBS" 14 "SOE" 25 "NURS-NK" 30 "PHARM" 33 "RBS-NB" 77 "NURS-NB"
label values nCollege college_cd

save acad.dta, replace  // Save downloaded data set as Stata data file in working directory

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTMTSSQSn5EOcxo3CEX6D_sx9VBtO9Nag9nSSLu6ZVHSx-apC9FsEnKJlhVtUkJ_g/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     // In this data set, I'm seeing a STEM Major flag and URM indicator along with residency, state, zip, etc.
summarize    // The data consists of 53.6% of students being a STEM major, 50% female, and 20.7% URM
tab STATE, sort     // New Jersey is the most common state with 84% of students having an NJ value
tab RESIDENCY, sort // Similar to above, 84% of students are in-state.  New Jersey students serve as base case.

generate INTL = . // Generate an International student dummy variable from current RESIDENCY variable
replace INTL = 1 if RESIDENCY == "INTL"  // 
replace INTL = 0 if RESIDENCY != "INTL"  // All other values equal 0
label variable INTL "International Student"
tab RESIDENCY INTL, mi // Checking cross-tab to make sure above coding worked as expected

generate OOS = . // Generate an Out-of-State (OOS) student dummy variable from current RESIDENCY variable
replace OOS = 1 if RESIDENCY == "OOS"  // 
replace OOS = 0 if RESIDENCY != "OOS"  // All other values equal 0
label variable OOS "Out-of-State Student"
tab RESIDENCY OOS, mi // Checking cross-tab to make sure above coding worked as expected

// Label variables

label variable STEM_IND "Academic Interest in STEM"
label variable FEMALE "Female"
label variable STATE "State"
label variable COUNTY "New Jersey County of Residence"
label variable CEEB "High School CEEB"
label variable HS_NAME "High School Name"
label variable URM_IND "Underrepresented Minority"
label variable ETHNICITY "Race/Ethnicity"

tab COUNTY  // Display county values for future join re-code

save demo.dta, replace  // Save data set as Stata data file in working directory

merge 1:1 ID using acad, generate(_mergeda) //  Academic file becomes using -- 28,006 records _merge ==3 (Matched), 0 records unmatched

set linesize 240  // Increase screen width size

list in 1/10 // Preview of matched records with _merge field

save student.dta, replace  // Save merged data set in working directory

tab COLLEGE_OF_APPLICATION HSGPA_BIN // Tabulate two fields -- one from each data source

tempfile FAFSAsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vQRMpzsvK9QIFRIqQ7Bp6Yb9af1aVWkIoiCEjP6RnQgel50WOa-380k5d-LGe3wdQ/pub?output=xlsx" `FAFSAsheet', replace // copies data set from the web
import excel using `FAFSAsheet', first sheet("data") clear // Imports Excel file using local name

summarize
describe
tab OLDEFC  // No obs -- drop below
rename COSTOFATTENDANCE COA

drop OLDEFC

//  Create log variable transformations for regressions
generate LEFC = ln(EFC)
generate LAGI = ln(HOUSEHOLDAGI)

// Label variables
label variable EFC "Expected Family Contribution"
label variable HOUSEHOLDAGI "Student's Household Adjusted Gross Income"
label variable DEPSTAT "Dependency Status"
label variable NJEI "New Jersey Eligibility Index"
label variable SZ_HSD  "Size of Student's Household"
label variable NUMCOL_P "Number of persons in College"
label variable COA "Cost of Attendance"
label variable LEFC "Log (Expected Family Contribution)"
label variable LAGI "Log (Student's Household Adjusted Gross Income)"

save fafsa.dta, replace

merge 1:1 ID using student, generate(_mergesf)  // Previously merged student file becomes using
/*
Merged Outcome
Result	Number	of obs
		
Not matched		12,003
from master		7,864	(_mergesf==1)  Student is found only in master file (FAFSA) -- we don't need FAFSA filers who didn't attend the university
from using		4,139	(_mergesf==2)  Student is found only in using file (student)  -- we still want these records

Matched		23,867	(_mergesf==3)  Student appeard in both data sets

Our unit of analysis is students who entered the univeristy (whether or not they had a FAFSA submitted).  Therefore, we'll keep records with a merge match of 2 and 3.
This data set brings in student-level variables such as Adjusted Gross Income (AGI), Expected Family Contribution (EFC), their dependency status and others.
*/

keep if inlist(_mergesf,2, 3)

tab DEPSTAT, mi  // 18.7% of enrolling students do not have a FAFSA on record.  81.3% of enrolling students filed a FAFSA

save studentfa.dta, replace  // Save combined data set in working directory

tempfile HSsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vR45EjcDtQsGsSgdW28P9gnEX7g0M-3XcU_6pCsWXi6uIuDYLVPhLifj_mSBr5xmQ/pub?output=xlsx" `HSsheet', replace // copies data set from the web
import excel using `HSsheet', first sheet("data") clear // Imports Excel file using local name

describe
tab RURAL

// Rename variables for easier analysis
rename A_HS_COLLEGE_ACCESS HS_ACCESS
rename A_HS_EDUC_PTILE HS_ED_LVL
rename A_HS_MEDFAMINC_PTILE HS_MED_INC
rename A_HS_OVERALL_PTILE HS_OVERALL_SCORE
rename RURAL LOCALE

// Label variables:  Information from: https://secure-media.collegeboard.org/landscape/comprehensive-data-methodology-overview.pdf
label variable HS_ACCESS "High School College Attedance Indicator"
label variable HS_ED_LVL "High School Typical Education Level Indicator"
label variable HS_MED_INC "High School Median Family Income Indicator"
label variable HS_OVERALL_SCORE "High School Overall Indicator"
label variable LOCALE "High School Location Geographic Area"

save hslandscape.dta, replace

use studentfa, clear

merge m:1 CEEB using hslandscape, generate(_mergeshs)

/*
Merged Outcome
Result	Number	of obs
		
Not matched		7,836
from master		3	(_mergeshs==1)  Record found only in master file (Student file)  Students with either no CEEB or CEEB  not in file, will investigate
from using		7,833	(_mergeshs==2)  Record found only in using file (HS CEEB Landscape)  So, HSCEEBs provided but no students are represented from them

Matched		28,003	(_mergeshs==3)  CEEB appears in both files

*/

tab CEEB if _mergeshs == 1

/*
Investigating three CEEBS.  They are 053571 (Pacific Coast HS in CA), 182048 (Owensboro HS in KY), and 671132 (Heritage School India).  Exceeded expectations that only 3 students came from high schools not in the College Board file.  There are only 3 total with 1 from each school.  OK to continue.
*/

keep if inlist(_mergeshs, 3, 1)

save studentFAHS, replace

// Per Capita Personal Income for all NJ counties: https://nj.gov/labor/lpa/industry/incpov/incpoverty_index.html
// Data source:  the State of New Jersey Department of Labor and Workforce Development: US Department of Commerce Bureau of Economic Analysis

/* NJ County Per Capital Personal Income data set.  This data set contains Per Capita Personal Income for each NJ county.  The dollar estimates are in thousands of current dollars.  Per Capita personal income was computed using Census Bureau midyear population estimates.  Data reflect those available as of March 2020.
*/

tempfile Ctysheet     // Temporarily assign file name gsheet
copy "https://nj.gov/labor/lpa/industry/incpov/pcicnty.xls" `Ctysheet', replace // copies data set from the web
import excel using `Ctysheet', cellrange(A6:BA28) firstrow case(preserve) clear // Imports Excel file using local name

describe

// After reviewing the data, the year column labels did not come in.  I searched the internet and found that Stata doesn't like numeric variable names.  The same internet search yielded
// this solution: https://blog.stata.com/2012/06/25/using-import-excel-with-real-world-data/

foreach var of varlist _all {
	local label : variable label `var'
	local new_name = lower(strtoname("`label'"))
	rename `var' `new_name'
}

describe // Checking to make sure above code worked as expected

// Need to create a matching ID field in new data for each county

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

use studentFAHS, clear
destring YR, replace  // Converted YR to numeric for match
save studentFAHS, replace

merge m:1 COUNTY YR using countylong, generate(_mergecty)

/*
Merged Outcome

Result	Number	of obs
		
Not matched		4,696
from master		4,560	(_mergecty==1)  Record found only in Master file (Student data without matching NJ county)
from using		136	(_mergecty==2) Record found only in using file (NJ County) but not in student file, will review

Matched		23,446	(_mergecty==3) NJ county appears in both data sets
    -----------------------------------------
*/

tab COUNTY YR if _mergecty == 2
// "NJ" placeholder or row accounts for 10.  The others are a single occurence of each NJ county for each year.  OK to discard.

keep if inlist(_mergecty, 3, 1)

save studentFAHSCTY, replace

/* NJ County Residential Housing Units Building Permits data set.  This data set contains total single- and multi-family residential housing units authorized for building permits for each NJ county.  Data reflect those available from the US Census Bureau, Manufacturing & Construction Division
*/

tempfile Permsheet     // Temporarily assign file name gsheet
copy "https://nj.gov/labor/lpa/industry/bp/hist10/county10to18.xlsx" `Permsheet', replace // copies data set from the web
import excel using `Permsheet', cellrange(A3:K27) firstrow case(preserve) clear // Imports Excel file using local name

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

use studentFAHSCTY.dta, clear

merge m:1 COUNTY YR using countylongpermit, generate(_mergectyp)

/*
Merged Outcome
    Result                      Number of obs
    -----------------------------------------
    Not matched                         4,674
        from master                     4,560  (_mergectyp==1)  Records found only in Master.  Represent out-of-state or international students with no NJ county
        from using                        114  (_mergectyp==2)  Records found only in Using.  Need to investigate below

    Matched                            23,446  (_mergectyp==3) Matched on both sides
    -----------------------------------------
*/	

tab STATE _mergectyp, mi  // Showing 4,560 records with no match with only 6 from NJ.  114 _mergectyp==3 have no STATE

tab STATE COUNTY if _mergectyp == 1, mi

tab STATE if COUNTY == "", mi   // 6 students from NJ do not have a COUNTY value in source file.

list ID ZIP HS_NAME if STATE == "NJ" & COUNTY == ""  // Manual review cases -- they appear to be in-state students attending an OOO high schools

keep if inlist(_mergecty, 3, 1)  // Data set contains 28,006 original student records for analysis

save studentFAHSCTYPERM, replace

tempfile Enrollsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTUQKb2BKqam66wfdO-sOPmNS2D6fDPprs9tjYid3fD8ZMlc6qaC-QecWgpCA0Y4g/pub?output=xlsx" `Enrollsheet', replace // copies data set from the web
import excel using `Enrollsheet', first sheet("data") clear // Imports Excel file using local name

destring YR, replace  // Converted YR to numeric for match

//  Shorten current variable names for easier reference later on during analysis
rename Enrolled TERM1
label variable TERM1 "First Term Enrolled"

rename First_Term_Status TERM1Stat
label variable TERM1Stat "First Term Attendance Status"

rename First_Term_Credits TERM1Cr
label variable TERM1Cr "First Term Credits Attempted"

rename First_Term_GPA TERM1GPA
label variable TERM1GPA "First Term Grade Point Average"

rename Second_Term_Status TERM2Stat
label variable TERM2Stat "Second Term Attendance Status"

rename Second_Term_Credits TERM2Cr
label variable TERM2Cr "Second Term Credits Attempted"

rename First_Year_GPA FY_GPA
label variable FY_GPA "First Year Grade Point Average"

rename Sophomore_Retention TERM3
label variable TERM3 "First to Second Year Retention"

replace TERM2Stat = 3 if TERM2Stat == .

label define att_stat 1 "Full-time" 2 "Part-time" 3 "No longer enrolled"

label values TERM1Stat TERM2Stat att_stat

save enroll, replace

merge 1:1 ID using studentFAHSCTYPERM, generate(_mergeout)

keep if inlist(_mergeout, 3)  // Data set contains 28,006 original student records for analysis

label variable percap "New Jersey County Per Capita Personal Income Prior-Prior Year"

label variable ctypermits "New Jersey County Residential Housing Permits Three Years Prior"

drop _merge*

save master, replace


***  Descriptive Statistics ***

outreg2 * using SummaryStats.xls, replace sum(log) keep(FY_GPA HSGPA SAT_M SAT_V HS_TOP10 ///
HSRNK_MIS FEMALE URM_IND STEM_IND)

*** Graphs ***

//preserve
//set seed 2038947 // specifies initial value of random number for sampling function  commented out, saved for later use

//sample 15, by(SCHOOL)

graph matrix HSGPA SAT_V SAT_M FY_GPA, half
graph export Scatter1.eps, replace  //  EPS format for better resolution

graph matrix HSGPA SAT_V SAT_M TERM1GPA, half
graph export Scatter2.eps, replace  //  EPS format for better resolution

pwcorr FY_GPA HSGPA SAT_M SAT_V, sig star(0.05)

graph box SAT_V SAT_M
graph export SATBox.eps, replace

graph bar FY_GPA, over(HSGPA_BIN)
graph export HSGPABinbar.eps, replace

graph hbar FY_GPA, over(RESIDENCY) blabel(bar, format(%4.3f)) ytitle("Average First-Year GPA")
graph export REShbar.eps, replace

graph box FY_GPA, over(URM_IND)
graph export URMbox.eps, replace

// restore

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

restore

histogram HSGPA, normal
graph export histHSGPA.eps, replace

histogram TERM1GPA, normal
graph export histTERM1GPA.eps, replace

histogram FY_GPA, normal
graph export histFYGPA.eps, replace

histogram EFC, normal
graph export histEFC.eps, replace

histogram HOUSEHOLDAGI, normal
graph export histAGI.eps, replace

histogram LEFC, normal
graph export histLEFC.eps, replace

histogram LAGI, normal
graph export histLAGI.eps, replace

twoway (scatter TERM1GPA SAT_M, color(%15 "204 0 51") lcolor(black)) ///
(scatter TERM1GPA SAT_V, color(%5 "95 106 114") lcolor(black)), ///
legend(order(1 "SAT Math" 2 "SAT Verbal")) ///
name(scatter1, replace)
graph export TERM1GPASAT.eps, replace

graph dot (p25) HSGPA (p75) HSGPA if YR < 2021, over(nCollege) ///
title("Incoming First-Year Students") ///
subtitle("Middle 50% HSGPA") ///
legend(label(1 "25th percentile") label(2 "75th percentile"))
graph export dot1.eps, replace

graph dot (p25) FY_GPA (p75) FY_GPA if YR < 2021, over(nCollege) ///
title("Incoming First-Year Students") ///
subtitle("Middle 50% First Year GPA") ///
legend(label(1 "25th percentile") label(2 "75th percentile"))
graph export dot2.eps, replace


scatter FY_GPA HSGPA || lfit FY_GPA HSGPA ||, by(SCHOOL, total row(2))
graph export scatterunit.eps, replace

twoway lfitci FY_GPA HSGPA
graph export linear1.eps, replace

preserve

sample 15

twoway lfitci FY_GPA HSGPA
graph export linear2.eps, replace

restore

*** Regressions ***

regress FY_GPA HSGPA
estimates store Model_1

regress FY_GPA HSGPA SAT_M SAT_V
estimates store Model_2

regress FY_GPA HSGPA SAT_M SAT_V FEMALE URM_IND
estimates store Model_3

regress FY_GPA HSGPA SAT_M SAT_V FEMALE URM_IND STEM_IND OOS INTL
estimates store Model_4

regress FY_GPA HSGPA SAT_M SAT_V FEMALE URM_IND STEM_IND OOS INTL LAGI
estimates store Model_5

regress FY_GPA HSGPA SAT_M SAT_V FEMALE URM_IND STEM_IND OOS INTL LAGI LEFC
estimates store Model_6

* Regression Table using esttab
esttab Model_* using "estimates.csv" , replace order(_cons) ///
	mtitle label stats(rss df_r r2 F N) ///
	cells(b (fmt(3) star) se(par fmt(3))) varwidth(40) ///
	title("Table 1: Determinants of First-Year College GPA")
		
* Regression Table using estout
estout Model* using Regressions.xls, replace order(_cons) ///
   cells (b(star fmt(%9.3f))) stats(r2 F N, labels("R2" "F" "Number of obs") fmt(%9.2f)) ///
   varlabels(_cons Constant)  label legend

exit
