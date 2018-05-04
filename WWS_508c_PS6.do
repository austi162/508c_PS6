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
cd "C:\Users\Chris\Documents\Princeton\WWS Spring 2018\WWS 508c\PS6"
use probation_ps6

set more off
set matsize 10000
capture log close
pause on

*Download outreg2
ssc install outreg2
ssc install mdesc


********************************************************************************
**                                   P1                                       **
********************************************************************************
/*Plot the histogram of dist_from_cut, allowing for a discontinuity at zero. You 
may choose your bin width. Do students bunch on either side of the probation cutoff? 
If bunching is apparent, what mechanism might explain it? If bunching is apparent, 
is it large or small in comparison to other observed noise in the histogram? Do 
you think your results represent a threat to the regression discontinuity design?*/

mdesc
su

*Testing out different BWs. .25 seems to be preferrable. 
hist dist_from_cut,start(-2) w(0.05) xline(0) saving(histogram_1,replace)

hist dist_from_cut,start(-2) w(0.1) xline(0) saving(histogram_2,replace)

hist dist_from_cut,start(-2) w(0.25) xline(0) saving(histogram_3,replace)


/*There appears to be slight bunching, but it is hard to discern if it is statistically
significant. If it is, then we would have reason to believe that students knew of
the cutoff ex-ante; this would threaten the SRD due to selection bias. We can also
test other background covariates to see if they are smooth across the cutoff period
to better understand if RD is still valid.*/

********************************************************************************
**                                   P2                                      **
********************************************************************************
/*The last five variables in the dataset are predetermined. Test whether the conditional 
expectations of these variables change discontinuously at the cutoff. Do you think 
your results represent a threat to the regression discontinuity design?*/

*Generate bins for running variable: dist_from_cut
**Note on (floor) command: rounds values down to the next lowest defined interval; 
**Argument: interval x floor(expression/interval); assuming we want 0.25 GPA intervals: 
gen bin = .25*floor(dist_from_cut/.25)
bysort bin: egen dist_from_cut_mean = mean(dist_from_cut)

*Generage mean values for 5 background covariates + immediate and mid-term outcomes:
foreach i in probation_year1 probation_ever left_school nextGPA gradin4 ///
gradin5 gradin6 hsgrade_pct male age_at_entry bpl_north_america english {
	bysort bin: egen `i'_mean = mean(`i')
	label var `i'_mean "local means"
}

*Graph scatterplots for covariates along generated bins
sort dist_from_cut
foreach i of varlist hsgrade_pct_mean-english_mean {
	scatter `i' bin, mcolor(black) msymbol(Oh) xline(0) name(`i', replace) nodraw
}
graph combine male_mean age_at_entry_mean bpl_north_america_mean english_mean hsgrade_pct_mean

/*So far, only Born in North America could potentially be discontinuous. Once we 
change the bin width to 0.1 GPA points, we can confirm continuity. Otherwise, 
all background covariates conditional on the running variable appear smooth at 
the 0.25 bin width and do not seem to discredit our RD design.*/

********************************************************************************
**                                   P3                                      **
********************************************************************************
/*Estimate the effect of falling below the cutoff on the probability of being placed 
on 1st-year probation. Also estimate the effect of falling below the cutoff on the 
probability of ever being placed on probation. Which effect is larger? Why?*/

*Generate fourth-order polynomial terms for continuous running variable:
local i = 2
while `i' <= 4 {
	gen dist_from_cut`i' = dist_from_cut^`i'
	local i = `i' + 1
}

*Generate Eligibility Z_i: right if scored above threshold
gen right = dist_from_cut > 0

*Interact eligibility term "right" with running variable polinomial terms:
foreach i in dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4 {
	gen r`i' = right*`i'
}

*Define locals for following regressions
local running dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4
local cutoff rdist_from_cut rdist_from_cut2 rdist_from_cut3 rdist_from_cut4
local controls male age_at_entry bpl_north_america english hsgrade_pct

*Effect of falling below cutoff on the probability of placed on probation 1st year:
reg probation_year1 right `running' `cutoff'
predict probation_year1_hat_poly
label var probation_year1_hat_poly "Year1 Poly"

*Check robustness by including background covariates; results don't change
reg probation_year1 right `running' `cutoff' `controls'
predict probation_year1_hat_poly_c
label var probation_year1_hat_poly_c "Year1 Poly w/ Controls"

*Effect of falling below cutoff on the probability of placed on probation ever:
reg probation_ever right `running' `cutoff'
predict probation_ever_hat_poly
label var probation_ever_hat_poly "Ever Poly"

*Check robustness by including background covariates; results don't change
reg probation_ever right `running' `cutoff' `controls'
predict probation_ever_hat_poly_c
label var probation_ever_hat_poly_c "Ever Poly w/ Controls"

*Check local linear results:
reg probation_year1 right if abs(dist_from_cut)<0.25
reg probation_year1 right dist_from_cut rdist_from_cut if abs(dist_from_cut)<0.25
predict probation_year1_hat_locallinear if abs(dist_from_cut)<0.25

reg probation_ever right if abs(dist_from_cut)<0.25
reg probation_ever right dist_from_cut rdist_from_cut if abs(dist_from_cut)<0.25
predict probation_ever_hat_locallinear if abs(dist_from_cut)<0.25


/*Falling just below the cutoff leads you to be 67 percentage-points more likely 
to be placed on probation your first year. Conversley, falling just above the 
cutoff leads students to be 67 percentage-points less likely to be placed on probation 
their first year. 

Falling just below the cutoff leads students to be 44 percentage-points more likely 
to be placed on probation ever, less than the first year outcome variable. This 
suggests that the benefits of the program are most effective the first year and 
taper over time.*/

********************************************************************************
**                                   P4                                      **
********************************************************************************
/*For 1st-year probation and ever probation, create graphs that plot the local 
means and the polynomial fit against the running variable. You may choose your bin 
width for the local means. Describe how the two graphs relate to your results for 
question (3).*/

*Plotting predicted values for probation in year 1 if just above cutoff

sort dist_from_cut
twoway (scatter probation_year1_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit probation_year1_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) ///
       (fpfit probation_year1_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (line probation_year1_hat_locallinear dist_from_cut if dist_from_cut<0,lcolor(lime)) ///
       (fpfit probation_year1_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) ///
       (fpfit probation_year1_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)) /// 
       (line probation_year1_hat_locallinear dist_from_cut if dist_from_cut>0,lcolor(lime)), ///
       saving(RD_graph_4a, replace) xline(0) legend(order(1 2 3 4))

twoway (scatter probation_year1_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit probation_ever_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) /// 
       (fpfit probation_ever_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (line probation_ever_hat_locallinear dist_from_cut if dist_from_cut<0,lcolor(lime)) ///
       (fpfit probation_ever_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) /// 
       (fpfit probation_ever_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)) /// 
       (line probation_ever_hat_locallinear dist_from_cut if dist_from_cut>0,lcolor(lime)), ///
       saving(RD_graph_4b, replace) xline(0) legend(order(1 2 3 4))

pause

/*The two graphs confirm that treatment effects attenuate over time. Students 
above the cutoff are more likely to be on probation at some point during their
time at university compared to the first year, which is effectively 0 probability.*/
********************************************************************************
**                                   P5                                       **
********************************************************************************
/*Estimate the effect of falling below the cutoff on medium-term outcomes: the 2nd-
year GPA and the probability of dropping out of the university after the 1st year.
	• Do you think it is reasonable to interpret the discontinuity in dropout rates 
	  as the effect of actually being placed on probation after the first year? 
	  Why or why not?
	• Given that falling below the cutoff affects dropout, do you think the estimated
	  effect on the 2nd-year GPA is unbiased?*/

*Define locals for following regressions
local running dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4
local cutoff rdist_from_cut rdist_from_cut2 rdist_from_cut3 rdist_from_cut4
local controls male age_at_entry bpl_north_america english hsgrade_pct

*Effect of falling below cutoff on 2nd-year GPA:
reg nextGPA right `running' `cutoff'
predict nextGPA_hat_poly
label var nextGPA_hat_poly "NextGPA Poly"

*Check robustness by including background covariates; results don't change
reg nextGPA right `running' `cutoff' `controls'
predict nextGPA_hat_poly_c
label var nextGPA_hat_poly_c "NextGPA Poly w/ Controls"

/*Students just below the cutoff have second year GPAs that are .17 grade points
lower than students just bove the cutoff. Because the running variable and background
covariates are smooth at the cutoff, this can be interpreted as a causal effect*/

*Effect of falling below cutoff on probability of dropping out after the 1st year:
reg left_school right `running' `cutoff'
predict left_school_hat_poly
label var left_school_hat_poly "Left School Poly"

*Check robustness by including background covariates; results don't change
reg left_school right `running' `cutoff' `controls'
predict left_school_hat_poly_c
label var left_school_hat_poly_c "Left School Poly w/ Controls"

/*Students just below the cutoff are .15 percentage-points less likely to drop out
of university than students just bove the cutoff. This is biased. If those likely
to drop out have lower than average GPAs, then the effect on GPA is likely 
upward biased*/

sort dist_from_cut
twoway (scatter left_school_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit left_school_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) ///
       (fpfit left_school_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (fpfit left_school_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) ///
       (fpfit left_school_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)), ///
       saving(RD_graph_5a, replace) xline(0) legend(order(1 2 3 4))
	   
twoway (scatter nextGPA_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit nextGPA_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) ///
       (fpfit nextGPA_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (fpfit nextGPA_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) ///
       (fpfit nextGPA_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)), ///
       saving(RD_graph_5b, replace) xline(0) legend(order(1 2 3 4))
	   
pause

********************************************************************************
**                                   P6                                       **
********************************************************************************
/*Estimate the effect of falling below the cutoff on the probability of graduating
within 4, 5, and 6 years. Also estimate these effects separately for students who 
had above and below median grades in high school. Interpret your results.*/

*Define locals for following regressions
local running dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4
local cutoff rdist_from_cut rdist_from_cut2 rdist_from_cut3 rdist_from_cut4
local controls male age_at_entry bpl_north_america english hsgrade_pct

*Probation effect of falling below cutoff on graduating in 4 years
reg gradin4 right `running' `cutoff' 

/*Students just above the cutoff are 4.7 percentage-points more likely to graduate
in 4 years than those just below cutoff; significant at 90% CI*/

*Probation effect of falling below cutoff on graduating in 5 years
reg gradin5 right `running' `cutoff'

/*Students just above the cutoff are 5.7 percentage-points more likely to graduate
in 4 years than those just below cutoff; significant at 95% CI*/

*Probation effect of falling below cutoff on graduating in 6 years
reg gradin6 right `running' `cutoff'

/*Students just above the cutoff are 4.7 percentage-points more likely to graduate
in 4 years than those just below cutoff; significant at 90% CI*/

pause 

/*Probation effect of falling below cutoff on graduating in 4, 5 and 6 years for 
above/below median grade in high school*/
reg gradin4 right `running' `cutoff' if hsgrade_pct > 50
reg gradin4 right `running' `cutoff' if hsgrade_pct < 50

reg gradin5 right `running' `cutoff' if hsgrade_pct > 50
reg gradin5 right `running' `cutoff' if hsgrade_pct < 50

reg gradin6 right `running' `cutoff' if hsgrade_pct > 50
reg gradin6 right `running' `cutoff' if hsgrade_pct < 50

/*Only significant effects are that students below median high school grades who 
do not receive probation are more likely to graduate in 5 or 6 years. This suggests
that there are some long-term benefits to probation, if your objective is to get
students to graduate in 4 years.*/

********************************************************************************
**                                   P7                                       **
********************************************************************************
/*Suppose we thought that the graduation discontinuities were driven by an effect
of ever being placed on probation, rather than an effect of being placed on probation 
specifically after the first year. Use twostage least squares to estimate how ever 
being placed on probation affects the probability of graduating within 4, 5, and 
6 years. You do not need to perform separate analyses by high school ranking. How 
do your estimates relate to your results for questions (3) and (6)?*/ 

*2SLS to estimate how ever being placed on probation affects probability of graduating
* in 4 years.

**Interact endogenous variable (probation_ever) with running variable polinomial 
**terms for full RF regression:
foreach i in dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4 {
	gen T`i' = probation_ever*`i'
}
*Define locals for following regressions
local running dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4
local cutoff rdist_from_cut rdist_from_cut2 rdist_from_cut3 rdist_from_cut4
local controls male age_at_entry bpl_north_america english hsgrade_pct

local treated Tdist_from_cut Tdist_from_cut2 Tdist_from_cut3 Tdist_from_cut4  

foreach i of varlist gradin4 gradin5 gradin6 {
	qui reg probation_ever dist_from_cut `running' `cutoff' 
	estimates store first_stage
	qui reg `i' dist_from_cut `running' `treated' 
	estimates store reduced_form
	suest first_stage reduced_form, r
	nlcom [reduced_form_mean]dist_from_cut/[first_stage_mean]dist_from_cut
	pause
}

/*Those ever on probation after just falling into probation their first year were
10 percentage-points less likely to graduate in 4 years than those who were never
on probation; significant at 99% CI.*/

/*Those ever on probation after just falling into probation their first year were
12 percentage-points less likely to graduate in 5 years than those who were never
on probation; significant at 99% CI.*/

/*Those ever on probation after just falling into probation their first year were
11 percentage-points less likely to graduate in 6 years than those who were never
on probation; significant at 99% CI.*/
