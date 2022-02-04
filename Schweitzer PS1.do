clear all
// change dir
sysdir     //  Lists Stata's system directories

mkdir ~/Desktop/DataMgmt     // Make directory
// adopath + ~/Desktop/DataMgmt  holding line for now since no installed Stata commands are needed

cd ~/Desktop/DataMgmt     // Change directory to recently created one above

log using Schweitzer_PS1.txt, replace   // Create log of session

pwd     // Command to provide present working directory


/*
******************************************************
Project Name: Data Management Problem Set #1 dofile
Jason Schweitzer
Preamble: this file pulls down two data sets: 1.) a list of incoming first-year students at a public research university in the Northeast with their academic credentials (HSGPA, SAT scores, etc.) and
2.) incoming student demographic information such as race/ethnicity, gender, high school, zipcode, etc.
In order to begin to answer the following research questions:
1.) What factors have an effect on students' grade performance at the University?
2.) What factors have an effect on early retention progress at the University?
//there's a ton of data at https://nces.ed.gov/
******************************************************

*/

version 17     // Declares the Stata version do file was written in
set matsize 800     // Sets the maximum number of variables to specific amount, default is 400

* Student academics data set  This data set contains information pulled from an institutional admissions table and contains a contrived ID and their HS academic credentials such as HSGPA and SAT scores.

//cite data properly give url todata source!
tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vRJ05CdMHfbzNR9AKHrzYJ7Hj5swUzxESo6YJn2ZDV7uhydeZe6X9p_K6GbpQSaCw/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     //  In this data, I'm seeing students' high school GPA, SAT scores, ACT score, an admissions index, HSRANK, and some subject-specific HSGPAs.
summarize    //  The average HSGPA was 3.75 on a 4.5 scale, average SAT scores were 644 for Verbal and 677 for Math with expected values of 800 for maximum of each.
tab YR       //  The file contains incoming students from the years 2018 to 2021 ranging from the low in 2020 of 6,553 to the high of 7,310 in 2019.

save acad.dta, replace  // Save downloaded data set as Stata data file in working directory

outsheet using acad.csv, replace comma nolabel // Export data set to csv format -- replace added to over-write existing file


* Student demographic data set This data set contains information pulled from a Customer Relationship Management (CRM) database and contains demographic information about the incoming cohort.
//ok good, you say where its from; but again also give url

tempfile gsheet     // Temporarily assign file name gsheet
copy "https://docs.google.com/spreadsheets/d/e/2PACX-1vTMTSSQSn5EOcxo3CEX6D_sx9VBtO9Nag9nSSLu6ZVHSx-apC9FsEnKJlhVtUkJ_g/pub?output=xlsx" `gsheet', replace // copies data set from the web
import excel using `gsheet', first sheet("data") clear // Imports Excel file using local name

describe     // In this data set, I'm seeing a STEM Major flag and URM indicator along with residency, state, zip, etc.
summarize    // The data consists of 53.6% of students being a STEM major, 50% female, and 20.7% URM
tab STATE, sort     // New Jersey is the most common state with 84% of students having an NJ value
tab RESIDENCY, sort // Similar to above, 84% of students are in-state

save demo.dta, replace  // Save data set as Stata data file in working directory

export excel using "demo.xlsx", firstrow(variables)     // Export to Excel and make first row variable names

exit



