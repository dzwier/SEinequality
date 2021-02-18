*==============================================================================*
*       		Shadow education II: main analysis       				   	   *
/*=============================================================================*
*-------------------------------------------------------------------------------
 Project: Zwier, D., Geven, S., & van de Werfhorst, H.G. (2021). Social inequality 
 in shadow education: The role of high-stakes testing. 
 https://doi.org/10.1177/0020715220984500
 
 
 Data: The Programme for International Student Assessment (PISA) 2012 
 Last edited 19-11-2020
 Stata version: 16.1
*-------------------------------------------------------------------------------
	
	1. Open data
	2. Export Figure 1: Descriptive statistics SE 
	3. Export Table 1: Descriptive statistics of student-level variables
	4. Estimate models 
	5. Export Table 3-6: multilevel regression results (LPMs)
	6. Export Figure 2: AMEs SES##central exams

*==============================================================================*/
* 1. Open data             		   
*==============================================================================*

	use "$posted/workingdata.dta", clear

*** Harmonize N samples (dichotomous variables)
	local vlist ses, gender, age, igrade, immig
	foreach dv in D_OSLmath D_OSLlang D_CC D_PT {
		gen sample_`dv' =! missing(`dv', `vlist')
		
		distinct SCHOOLID if sample_`dv'
	}
	
*** Define global macro control variables
	global controls gender age igrade i.immig 
	
*** Set PVMATH and PVREAD as imputed values
	gen PV0MATH100=. 
	gen PV0READ100=. 
	
	mi import wide, ///
		imputed(PV0MATH100 = PV1MATH100 PV2MATH100 PV3MATH100 PV4MATH100 PV5MATH100 ///
				PV0READ100 = PV1READ100 PV2READ100 PV3READ100 PV4READ100 PV5READ100) clear
	mi describe 
	
*==============================================================================*/
* 2. Export Figure 1: Descriptives SE           		   
*==============================================================================*

*** Define titles graphs
	local titlelist "A. Out-of-school-time lessons in mathematics" ///
		"B. Out-of-school-time lessons in language" "C. Personal tutor" ///
		"D. Commercial company lessons"
	
*** Make subgraphs
	foreach var in OSLmath OSLlang PT CC {
		preserve
			// calculate mean
			collapse (mean) S_`var'=S_`var' (mean) D_`var'=D_`var' [aw=W_FSTUWT], by(CNT) 
			
			// fix axis labels
			quietly sum S_`var'
			local ymax = ceil(r(max))
			
			// define title
			local i = `i'+1
			local title : word `i' of "`titlelist'"
				
			// fix labels
			sort D_`var'
			gen grp 	= _n
			gen grp2 	= (2*_n)-1 +_n-1
			gen gr2		= grp2 + 1
			labmask gr2, values(CNT)
			
			// graph
			twoway bar D_`var' grp2, col(gs2) yaxis(1) scheme(plotplain) ///
				ytitle("Proportion", axis(1) size(small)) ylab(0(.2)1, axis(1)) || ///
				bar S_`var' gr2, yaxis(2) xlab(2(3)161, valuelabel angle(90) labsize(vsmall) nogrid notick) ///
				ytitle("Number of hours", axis(2) size(small)) ylab(0(1)`ymax', axis(2)) ///
				legend(order(1 "Participation rate" 2 "Number of hours") pos(6) rows(1) size(vsmall)) ///
				xsize(9) xtitle("") name(des_`var', replace) title("`title'", pos(12) size(small) ring(0)) ///
				graphregion(margin(vsmall)) plotregion(margin(b=0))
				*graph export "$figures/des_`var'.png", width(4000) replace
				window manage close graph 
		restore
	}
	grc1leg des_OSLmath des_OSLlang des_PT des_CC, ///
		rows(4) imargin(vsmall) name(Figure1, replace) 
	graph display Figure1, xsize(10) ysize(13)
	graph export "$figures/Figure1.png", width(4000) name(Figure1) replace
	window manage close graph Figure1

*==============================================================================*/
* 3. Export Table 1: Descriptive statistics of student-level variables	   	   *
*==============================================================================*

	quietly tab immig, gen(immig_)
	lab var immig_1 "Native"
	lab var immig_2 "First-generation"
	lab var immig_3 "Second-generation"

	eststo des: estpost sum D_OSLlang D_OSLmath D_PT D_CC ses 				///
	PV*MATH100 PV*READ100													///
	gender age igrade immig_* [aw=W_FSTUWT]
	
	esttab des using "$tables\Table 1.rtf", 								///
		cells("mean(fmt(2)) min(fmt(2)) max(fmt(2)) sd(fmt(2)) count(fmt(%6.0f))") ///
		nogap label compress mlabels(none) nonumber modelwidth(10)			///
		title("Table 1. Descriptive statistics of the student-level variables.") ///
		addnotes("Note: PISA 2012, own calculations.") replace 
	drop immig_*

*==============================================================================*/
* 4. Estimate Models    	   								   			   	   *
*==============================================================================*

*** Rename labels for table display
	lab var c_selage 	"Tracking age"
	lab var ses 		"SES"
	lab var PV0MATH100	"Performance (PVMATH)"
	lab var PV0READ100	"Performance (PVREAD)"
	lab var gender 		"Female"
	lab var igrade		"Grade"
	lab var age			"Age"

	egen unique_schoolid = group(CNT SCHOOLID) // gen schoolid for FE estimation
		
*** Run all models
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		dis "`var'"

		// M0: Intercept only model
		mixed 	`var' [pw=wwgt54] if sample_`var'==1 		///
				|| CNT: || SCHOOLID:, pw(W_FSCHWT)  	
		est store m0_`var'

		local var_c = exp(2*[lns1_1_1]_b[_cons]) 	// var(country)
		local var_s = exp(2*[lns2_1_1]_b[_cons]) 	// var(school)
		local var_e = exp(2*[lnsig_e]_b[_cons]) 	// var(residual)

		* ICC: var(_cons)/(var(_cons)+var(_cons)+var(Residual))
		di "Country ICC:" (`var_c'/(`var_c'+`var_s'+`var_e'))*100
		di "School ICC:" (`var_s'/(`var_c'+`var_s'+`var_e'))*100

		// M1: Random intercept and Random slope models
		/*
		mixed 	`var' $controls ses [pw=wwgt54] 			///
				|| CNT: || SCHOOLID:, pw(W_FSCHWT)  

		mixed 	`var' $controls ses HST [pw=wwgt54] 		///
				|| CNT: || SCHOOLID:, pw(W_FSCHWT)  
		*/
		
		mixed 	`var' $controls ses HST [pw=wwgt54] 		///
				|| CNT: ses || SCHOOLID:, pw(W_FSCHWT)  
		est store m1_`var'

		// M2: cross-level interaction HST#SES
		mixed 	`var' $controls c.HST##c.ses [pw=wwgt54] 	///
				|| CNT: ses || SCHOOLID:, pw(W_FSCHWT) 
		est store m2_`var'

		// M3: add performance to M2
		*use PVREAD for models S_OLSlang, PVMATH for other DVs
		if "`var'" == "S_OSLlang" local PV PV0READ100
		else local PV PV0MATH100
		
		mi est, post var: mixed `var'	 					///
				$controls c.HST##c.ses `PV' [pw=wwgt54] 	///
				|| CNT: ses || SCHOOLID: , pw(W_FSCHWT)  
		est store m3_`var'

		// M4: add tracking to M2
		mixed `var' $controls c.ses##c.HST c.c_selage c.c_selage#c.ses ///
				[pw=wwgt54] || CNT: ses || SCHOOLID: , pw(W_FSCHWT)  
		est store m4_`var'

		// M5: FE estimation
		mixed 	`var' $controls c.ses c.HST#c.ses i.n_CNT [pw=wwgt54] ///
				|| unique_schoolid:, pw(W_FSCHWT)
		est store mfix_`var'
}

*** Display models 	
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		esttab m0_`var' m1_`var' m2_`var' m4_`var' mfix_`var', ///
			b(%5.3f) se(%5.3f) obslast label ///
			scalars("ll Log likelihood") sfmt(%10.1f) nogap nobase nomtitle  ///
			transform(ln*: exp(2*@) 2*exp(2*@)) ///
			star(+ 0.10 * 0.05 ** 0.01 *** 0.001) indicate(country FE = *.n_CNT)
	}

*==============================================================================*/
* 5. Export Table 3-6: multilevel regression results (LPMs)	   			   	   *
*==============================================================================*	
	
	// Define titles tables
	local titlelist "out-of-school-time lessons in mathematics" ///
		"out-of-school-time lessons in language" "personal tutor" ///
		"commercial company lessons"
	
	// Export all tables with esttab
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		local i = `i'+1
		local dv : word `i' of "`titlelist'"

		esttab m0_`var' m1_`var' m2_`var' m3_`var' m4_`var' mfix_`var' ///
			using "$tables\Table_`var'.rtf", ///
			b(%5.3f) se(%5.3f) compress nogap nobase nomtitle label ///
			bic(%10.1f) scalars("ll Log likelihood") sfmt(%10.1f)  ///
			transform(#*: exp(2*@) 2*exp(2*@)) ///
			equations(2:3:3:3:3:., 3:4:4:4:4:2, 4:5:5:5:5:3, .:2:2:2:2:.) ///	
			eqlabels("" "var(country)" "var(school)" "var(residual)" "var(ses)", none) ///
			indicate(country FE = *.n_CNT) ///
			title("Table XXX. Results multilevel regression models `dv'.") 	///
			refcat(gender "\i Fixed part \i0" ///
				1.immig "Immigrant background (\i ref. = native \i0)" ///
				#1:_cons "Random part", nolabel) ///
			star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
			modelwidth(4) interaction(" * ") replace
	}
	
*==============================================================================*/
* 6. Export Figure 2: AMEs SES##central exams  								   *
*==============================================================================*

*** Estimate average marginal effects
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		
		// estimate margins
		est restore mfix_`var'
		eststo marfix_`var': margins, dydx(ses) at(HST=(0 1)) post	
	}
	
*** Make coeficient plot 
	coefplot ///
		(marfix_D_OSLmath, label("OSL mathematics") msym(t)) ///
		(marfix_D_OSLlang, label("OSL language") msym(d)) ///
		(marfix_D_PT, label("Personal tutoring") msym(o)) /// 
		(marfix_D_CC, label("Commercial company lessons") msym(s)), ///
		xline(0, lp(dash) lc(black)) ciopts(recast(rcap)) ///
		coeflabels(1._at = "No central exams" 2._at = "Central exams") ///
		xlab(-0.05(.05)0.12) xtitle("Average marginal effect SES")  ///
		level(90) legend(pos(4) rows(4)) ysize(4) xsize(7) ///
		mlabel format(%4.3f) mlabposition(6) ///
		plotregion(margin(l=0)) graphregion(margin(r-5))

*** Export plot
	graph export "$figures/Figure2.png", replace width(4000)
	window manage close graph 

	exit // end do-file