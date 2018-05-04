************* WWS508c PS3 *************
*  Spring 2018			              *
*  Author : Chris Austin              *
*  Email: chris.austin@princeton.edu  *
***************************************

/* Credit: Somya Bajaj, Joelle Gamble, Anastasia Korolkova, Luke Strathmann, Chris Austin
Last modified by: Chris Austin
Last modified on: 5/15/18 */

clear all

*Set directory, dta file, etc.
*cd "C:\Users\TerryMoon\Dropbox\Teaching Princeton\wws508c 2018S\ps\ps6"
cd "C:\Users\Chris\Documents\Princeton\WWS Spring 2018\WWS 508c\PS5\pS6"
use probation_ps6

set more off
set matsize 10000
capture log close
pause on
log using PS6.log, replace

*Download outreg2
ssc install outreg2
ssc install mdesc


********************************************************************************
**                                   P1                                       **
********************************************************************************
// Describe the data. Are there differences in conscription rates or crime rates 
// across birth years?

mdesc

su

foreach i in 1958 1959 1960 1961 1962 {
	di "Concripted rate and Crime Rate for birth cohort `i'"
	su conscripted if birthyr == `i'
	su crimerate if birthyr == `i'	
	di ""
}

graph bar conscripted, over(birthyr)

pause

graph bar crimerate, over(birthyr)

**Conscription rates were highest in 1958 and tapered by 1962. 
**Crime rates gradually increased from 1958 to 1962. There appears to be a 
**negative relationship between conscription and crime rate.

pause

********************************************************************************
**                                   P2                                      **
********************************************************************************
//
pause

********************************************************************************
**                                   P3                                      **
********************************************************************************
//
pause

********************************************************************************
**                                   P4                                      **
********************************************************************************
/

pause

********************************************************************************
**                                   P5                                       **
********************************************************************************
//

pause

********************************************************************************
**                                   P6                                       **
********************************************************************************
//

pause 

********************************************************************************
**                                   P7                                       **
********************************************************************************
// 


**

