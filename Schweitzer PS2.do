clear all
// change dir
sysdir     //  Lists Stata's system directories

capture mkdir ~/Desktop/DataMgmtPS2     // Make directory
// adopath + ~/Desktop/DataMgmt  holding line for now since no installed Stata commands are needed

cd ~/Desktop/DataMgmtPS2     // Change directory to recently created one above

capture log close

log using Schweitzer_PS2.txt, replace   // Create log of session

pwd     // Command to provide present working directory


/*
******************************************************
Project Name: Data Management Problem Set #2 dofile
Jason Schweitzer
Preamble: this file pulls down two data sets: 1.) a list of incoming first-year students at a public research university in the Northeast with their academic credentials (HSGPA, SAT scores, etc.) and
2.) incoming student demographic information such as race/ethnicity, gender, high school, zipcode, etc.
In order to answer the following research questions:
1.) What factors have an effect on students' grade performance at the University?
2.) What factors have an effect on early retention progress at the University?

******************************************************

*/

version 17     // Declares the Stata version do file was written in
set matsize 800     // Sets the maximum number of variables to specific amount, default is 400

/* Student academics data set  This data set contains information pulled from an institutional admissions table and contains a contrived ID and their HS academic credentials such as HSGPA and SAT scores. A sql query was created to extract the incoming first-year cohorts from a research intensive public university in the NorthEast.  Quantitative data points were pulled that are noted below.  The data were then stored on a public Google Drive with connection link presented below.
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

outsheet using acad.csv, replace comma nolabel // Export data set to csv format -- replace added to over-write existing file


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

tab COUNTY

save demo.dta, replace  // Save data set as Stata data file in working directory

export excel using "demo.xlsx", firstrow(variables) replace     // Export to Excel and make first row variable names

merge 1:1 ID using acad //  Academic file becomes using -- 28,006 records _merge ==3 (Matched), 0 records unmatched

set linesize 240  // Increase screen width size

list in 1/10 // Preview of matched records with _merge field
edit // Open up merged data set to further examine

save student.dta, replace  // Save merged data set in working directory

tab COLLEGE_OF_APPLICATION HSGPA_BIN // Tabulate two fields -- one from each data source

exit



