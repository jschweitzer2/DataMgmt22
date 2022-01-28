// Declaration of Stata version
version 17 //thats good

clear all
// change dir
cd "C:\Users\jcs313\OneDrive - Rutgers University\Documents\Data Management"

//but this wont work, bc we dont have this location
// import application data Excel file
import excel "C:\Users\jcs313\OneDrive - Rutgers University\Documents\Data Management\incoming student app data.xlsx", sheet("data") firstrow

//Summarize variables
summarize

// Describe data set
describe


// Tabulate variables
table YR
table YR NUM

edit
//again what datasets we would use?
