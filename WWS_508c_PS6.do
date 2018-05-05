************* WWS508c PS3 *************
*  Spring 2018			              *
*  Author : Chris Austin              *
*  Email: chris.austin@princeton.edu  *
***************************************

/* Credit: Somya Bajaj, Joelle Gamble, Anastasia Korolkova, Luke Strathmann, Chris Austin
Last modified by: Chris Austin
Last modified on: 5/14/18 */

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

*Testing out different bin widths. .25 seems to be preferrable. 
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

*Generate Eligibility Z_i: left if scored below threshold
gen left = dist_from_cut < 0

*Interact eligibility term "left" with running variable polinomial terms:
foreach i in dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4 {
	gen l`i' = left*`i'
}

*Define locals for following regressions
local running dist_from_cut dist_from_cut2 dist_from_cut3 dist_from_cut4
local cutoff ldist_from_cut ldist_from_cut2 ldist_from_cut3 ldist_from_cut4
local controls male age_at_entry bpl_north_america english hsgrade_pct

*Effect of falling below cutoff on the probability of placed on probation 1st year:
reg probation_year1 left `running' `cutoff'
predict probation_year1_hat_poly
label var probation_year1_hat_poly "Year1 Poly"

*Check robustness by including background covariates; results don't change
reg probation_year1 left `running' `cutoff' `controls'
predict probation_year1_hat_poly_c
label var probation_year1_hat_poly_c "Year1 Poly w/ Controls"

*Effect of falling below cutoff on the probability of placed on probation ever:
reg probation_ever left `running' `cutoff'
predict probation_ever_hat_poly
label var probation_ever_hat_poly "Ever Poly"

*Check robustness by including background covariates; results don't change
reg probation_ever left `running' `cutoff' `controls'
predict probation_ever_hat_poly_c
label var probation_ever_hat_poly_c "Ever Poly w/ Controls"

*Check local linear results:
reg probation_year1 left if abs(dist_from_cut)<0.25
reg probation_year1 left dist_from_cut ldist_from_cut if abs(dist_from_cut)<0.25
predict probation_year1_hat_locallinear if abs(dist_from_cut)<0.25

reg probation_ever left if abs(dist_from_cut)<0.25
reg probation_ever left dist_from_cut ldist_from_cut if abs(dist_from_cut)<0.25
predict probation_ever_hat_locallinear if abs(dist_from_cut)<0.25

/*Falling just below the cutoff leads you to be 99 percentage-points more likely 
to be placed on probation your first year.

Falling just below the cutoff leads students to be 62 percentage-points more likely 
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

/*The two graphs confirm that students above the cutoff their first year are more 
likely to be on probation at some point during their time at university compared 
to the first year, which is effectively 0 probability. This aligns with the results 
from Q3.*/

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
	  

*Effect of falling below cutoff on probability of dropping out after the 1st year:
reg left_school left `running' `cutoff'
predict left_school_hat_poly
label var left_school_hat_poly "Left School Poly"

*Check robustness by including background covariates; results don't change
reg left_school left `running' `cutoff' `controls'
predict left_school_hat_poly_c
label var left_school_hat_poly_c "Left School Poly w/ Controls"

/*Students just below the cutoff are 2 percentage-points more likely to drop out
of university than students just above the cutoff; this is signifcant at the 90% 
CI. This can be interpreted as a causal result given the continuity in the running
variable and background covariates.*/

*Effect of falling below cutoff on 2nd-year GPA:
reg nextGPA left `running' `cutoff'
predict nextGPA_hat_poly
label var nextGPA_hat_poly "NextGPA Poly"

*Check robustness by including background covariates; results don't change
reg nextGPA left `running' `cutoff' `controls'
predict nextGPA_hat_poly_c
label var nextGPA_hat_poly_c "NextGPA Poly w/ Controls"

/*Students just below the cutoff have second year GPAs that are .26 grade points
higher than students just above the cutoff. This is likely upward biased. If 
we assume that students with lower GPA's are more likely to drop out, then the
student composition that sticks around until year two have higher GPAs than they
would have otherwise.*/

sort dist_from_cut
twoway (scatter left_school_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit left_school_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) ///
       (fpfit left_school_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (fpfit left_school_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) ///
       (fpfit left_school_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)), ///
       saving(RD_graph_5a, replace) xline(0) legend(order(1 2 3))
	   
twoway (scatter nextGPA_mean bin,mcolor(black) msymbol(Oh)) ///
       (fpfit nextGPA_hat_poly dist_from_cut if dist_from_cut<0,lcolor(blue)) ///
       (fpfit nextGPA_hat_poly_c dist_from_cut if dist_from_cut<0,lcolor(red)) ///
       (fpfit nextGPA_hat_poly dist_from_cut if dist_from_cut>0,lcolor(blue)) ///
       (fpfit nextGPA_hat_poly_c dist_from_cut if dist_from_cut>0,lcolor(red)), ///
       saving(RD_graph_5b, replace) xline(0) legend(order(1 2 3))

********************************************************************************
**                                   P6                                       **
********************************************************************************
/*Estimate the effect of falling below the cutoff on the probability of graduating
within 4, 5, and 6 years. Also estimate these effects separately for students who 
had above and below median grades in high school. Interpret your results.*/

*Probation effect of falling below cutoff on graduating in 4 years
reg gradin4 left `running' `cutoff' 

reg gradin5 left `running' `cutoff'

reg gradin6 left `running' `cutoff'

/*All probation during first year effects on graduation time are significant 
insignificant.*/

/*Probation effect of falling below cutoff on graduating in 4, 5 and 6 years for 
above/below median grade in high school*/
reg gradin4 left `running' `cutoff' if hsgrade_pct > 50
reg gradin4 left `running' `cutoff' if hsgrade_pct < 50

reg gradin5 left `running' `cutoff' if hsgrade_pct > 50
reg gradin5 left `running' `cutoff' if hsgrade_pct < 50

reg gradin6 left `running' `cutoff' if hsgrade_pct > 50
reg gradin6 left `running' `cutoff' if hsgrade_pct < 50

/*Only significant effects are that students above median high school grade and 
who receive probation are 10 percentage-points less likely to graduate in 6 years.
Significant at the 90% CI. All other effects are statistically insignificant.

It is also important to note that 32% of data are missing for graduating in 4 years,
44% for graduating in 5 years, and 55% missing graduating in 6 years.*/

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
*in 4 years.

foreach i of varlist gradin4 gradin5 gradin6 {
	qui reg probation_ever left `running' `cutoff' 
	estimates store first_stage
	qui reg `i' left `running' `cutoff'
	estimates store reduced_form
	suest first_stage reduced_form, r
	nlcom [reduced_form_mean]left/[first_stage_mean]left
	pause
}


/*There are no statistically significant effects of ever being placed on probation
and graduating in 4, 5 or 6 years.

The answer to (3) demontrated that less students were likely to be put on
probation ever than probation in the first year (62 vs. 99%) if they fell below
the threshold. This means that the RF effect will be scaled up more for the effect 
of ever being on probation compared to probation in the first year.

These statistically insignifcant results align with Q6, suggesting that probation
is not important for graduation timing. Because it does not appear to help with
graduating on tie, and probation also drives students to drop out, I would not
recommend the probation policy for marginal students.*/
