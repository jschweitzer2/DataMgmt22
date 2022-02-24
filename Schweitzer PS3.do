clear all
// change dir

version 17     // Declares the Stata version do file was written in
sysdir     //  Lists Stata's system directories

capture mkdir ~/Desktop/DataMgmtPS3     // Make directory
// adopath + ~/Desktop/DataMgmt  holding line for now since no installed Stata commands are needed

cd ~/Desktop/DataMgmtPS3    // Change directory to recently created one above

capture log close

log using Schweitzer_PS3.txt, replace   // Create log of session

pwd     // Command to provide present working directory


/*
******************************************************
Project Name: Data Management Problem Set #3 dofile
Jason Schweitzer
Preamble: this file pulls down six data sets:
1.) a list of incoming first-year students at a public research university in the Northeast with their academic credentials (HSGPA, SAT scores, etc.) and
2.) incoming student demographic information such as race/ethnicity, gender, high school, zipcode, etc.
3.)  FAFSA information that lists students' EFC, dependency status, AGI, household size, etc. 
4.)  College Board Landscape Data: Rutgers subscribes to a paid data service called Landscape that supplies us with school-specific indices such as college access probability,
typical education level of the high school, median family income among those in the high school, its geographic setting (e.g. rural, urban, etc.), and an overall percentile score.
5.)  NJ County Data - Per Capital Personal Income by Year
6.)  NJ County Data -- Residential Housing Units Building Permits

More information on each of these data sets is chronicled below when the data are called upon

In order to answer the following research questions:
1.) What factors have an effect on students' grade performance at the University?
2.) What factors have an effect on early retention progress at the University?

******************************************************

*/

set matsize 800     // Sets the maximum number of variables to specific amount, default is 400

/* Student academics data set:  This data set contains information pulled from an institutional admissions table and contains a contrived ID and their HS academic credentials such as HSGPA and SAT scores. A sql query was created to extract the incoming first-year cohorts from a research intensive public university in the NorthEast.  Quantitative data points were pulled that are noted below.  The data were then stored on a public Google Drive with connection link presented below.  The database stores various data points about an applicant including their converted or weighted HSGPA which is calculated from specific HS courses and grades they receive.  Applicants enter this information via the SRAR:  Self-Reported Academic Record
*/

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vRJ05CdMHfbzNR9AKHrzYJ7Hj5swUzxESo6YJn2ZDV7uhydeZe6X9p_K6GbpQSaCw/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     //  In this data, I'm seeing students' high school GPA, SAT scores, ACT score, an admissions index, HSRANK, and some subject-specific HSGPAs.
summarize    //  The average HSGPA was 3.75 on a 4.5 scale, average SAT scores were 644 for Verbal and 677 for Math with expected values of 800 for maximum of each.
tab YR       //  The file contains incoming students from the years 2018 to 2021 ranging from the low in 2020 of 6,553 to the high of 7,310 in 2019.


recode HSRANK (90/max = 1) (nonm = 0), generate(HS_TOP10) // Generating HSRANK Top 10% dummy variable

tab HSRANK HS_TOP10, mi // Tabulate to check work to make sure recode worked as expected

bys YR COLLEGE_OF_APPLICATION: egen AVG_SAT = mean(SAT_TOTAL)    //Tabulate to check work to make sure recode worked as expected

list YR COLLEGE_OF_APPLICATION AVG_SAT if inlist(YR,"2019","2020") & inlist(COLLEGE_OF_APPLICATION,"25", "77"), sepby(YR COLLEGE_OF_APPLICATION) // Verifying data for a couple of years and units

preserve
collapse (count) ID, by(YR) // Counts student IDs by year to display cohort counts
list
restore

preserve
collapse HSGPA SAT_V SAT_M, by(YR) // Displays average (default) statistics on HSGPA and SAT scores for the four cohorts
list
restore

preserve
collapse (median) HSGPA SAT_V SAT_M, by(COLLEGE_OF_APPLICATION YR) // Displays median statistics on HSGPA and SAT scores for each academic area by year.
list
restore

keep if YR == "2021" // Keeping most recent year
tab YR

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vRJ05CdMHfbzNR9AKHrzYJ7Hj5swUzxESo6YJn2ZDV7uhydeZe6X9p_K6GbpQSaCw/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

preserve

describe
drop *CONV_GPA  // Dropping all subject matter specific GPAs from data set
describe

restore
describe

summarize HSGPA, detail
tab HSGPA, mi

recode HSGPA (min/3.52 = 1) (3.53/3.76 = 2) (3.76/4.02 = 3) (4.03/max = 4), generate(HSGPA_BIN) // Generating a categorical HSGPA variable based on percentiles of variable

tab HSGPA HSGPA_BIN, mi // Tabulate to check work to make sure recode worked as expected

save acad.dta, replace  // Save downloaded data set as Stata data file in working directory


/* Student demographic data set.  This data set contains information pulled from a different institutional admissions table Customer Relationship Management (CRM) database and contains a contrived ID and demographic information. A sql query was created to extract the incoming first-year cohorts from a research intensive public university in the NorthEast.  The data were then stored on a public Google Drive with connection link presented below.  The same parameters were used on the back-end during the query so a 1:1 match is expected.
*/

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTMTSSQSn5EOcxo3CEX6D_sx9VBtO9Nag9nSSLu6ZVHSx-apC9FsEnKJlhVtUkJ_g/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     // In this data set, I'm seeing a STEM Major flag and URM indicator along with residency, state, zip, etc.
summarize    // The data consists of 53.6% of students being a STEM major, 50% female, and 20.7% URM
tab STATE, sort     // New Jersey is the most common state with 84% of students having an NJ value
tab RESIDENCY, sort // Similar to above, 84% of students are in-state

generate RESIDENCY2 = . // Generate a NJ/Non-NJ resident variable from current RESIDENCY variable
replace RESIDENCY2 = 1 if RESIDENCY == "NJ"  // Dummy variable where NJ = 1
replace RESIDENCY2 = 0 if RESIDENCY != "NJ"  // All others equal 0
label variable RESIDENCY "NJ vs. Non-NJ Resident"
tab RESIDENCY RESIDENCY2, mi // Checking cross-tab to make sure above coding worked as expected


tab ETHNICITY
generate AFRAM_IND = .  // Generate African American dummy variable
replace AFRAM_IND = 1 if ETHNICITY == "African American"
replace AFRAM_IND = 0 if ETHNICITY != "African American"
label variable AFRAM_IND "African American Student"
tab ETHNICITY AFRAM_IND, mi

tab COUNTY  // Display county values for future join re-code

save demo.dta, replace  // Save data set as Stata data file in working directory

merge 1:1 ID using acad, generate(_mergeda) //  Academic file becomes using -- 28,006 records _merge ==3 (Matched), 0 records unmatched

set linesize 240  // Increase screen width size

list in 1/10 // Preview of matched records with _merge field
// browse // Open up merged data set to further examine  Commented out for now

save student.dta, replace  // Save merged data set in working directory

tab COLLEGE_OF_APPLICATION HSGPA_BIN // Tabulate two fields -- one from each data source


/* FAFSA filers data set.  This data set contains information collected from the Free Application for Federal Student Aid (FAFSA).  The data were provided by the Office of Financial Aid (OFA) within the university.  The data were then stored on a public Google Drive with connection link presented below.
*/

tempfile FAFSAsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vQRMpzsvK9QIFRIqQ7Bp6Yb9af1aVWkIoiCEjP6RnQgel50WOa-380k5d-LGe3wdQ/pub?output=xlsx" `FAFSAsheet', replace // copies data set from the web
import excel using `FAFSAsheet', first sheet("data") clear // Imports Excel file using local name


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


/* HSCEEB College Board Landscape data set.  This data set contains basic high school data (locale) and high school specific indicators such as college attendance, median family income, education levels, etc.  The data are provided as part of a subscription service the university has.  The data were extracted from their SFTP website and then stored on a public Google Drive with connection link presented below.
*/

tempfile HSsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vR45EjcDtQsGsSgdW28P9gnEX7g0M-3XcU_6pCsWXi6uIuDYLVPhLifj_mSBr5xmQ/pub?output=xlsx" `HSsheet', replace // copies data set from the web
import excel using `HSsheet', first sheet("data") clear // Imports Excel file using local name

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
browse

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

	
exit

