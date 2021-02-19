*==============================================================================*
* Shadow education III: main robustness checks 
/*=============================================================================*
*-------------------------------------------------------------------------------
 Project: Zwier, D., Geven, S., & van de Werfhorst, H.G. (2021). Social inequality 
 in shadow education: The role of high-stakes testing.
 https://doi.org/10.1177/0020715220984500
 
 
 Data: The Programme for International Student Assessment (PISA) 2012 
 Stata version: 16.1
*-------------------------------------------------------------------------------
	
	0. Set paths and install ados
	1. Robustness checks
		A. Analysis intensity (pseudo-)interval variables
		B. Components SES
		C. Outlier analysis

*==============================================================================*/
* 0. Set paths and install ados                    				  		   	   *
*==============================================================================*

*** --------- Specify your path here! -----------------------------------------*
	global dir 		"" 

*** Paths 
	global data 	"$dir/01_data"		// PISA 2012 and "countrydata"
	global posted 	"$dir/02_posted"	// prepared data ready for analysis
	global figures 	"$dir/03_figures"	// figures
	global tables 	"$dir/04_tables"	// tables
	
*** General settings 
	set more off, perm
	cap log close
	version 16.1
	
*** Install ados (if not installed yet) 
	*ssc install 	fre
	*ssc install 	estout
	*net install 	grc1leg.pkg	
	*ssc install 	blindschemes
	*ssc install 	scheme-burd
	*ssc install 	grstyle
	*net install 	gr0034.pkg 
	
*** Set graph scheme 
	set scheme burd5, perm
	grstyle init
	grstyle set plain, horizontal grid dotted // grid
	local p1      black
	local p2      gs8
	local p3      vermillion
	local p4      turquoise
	grstyle set color "`p1'" "`p2'" "`p3'" "`p4'"
	
*==============================================================================*/
* 2. Robustness checks 				     	   								   *
*==============================================================================*
* ------------------------------------------------------------------------------
*  A. Analysis use intensity (pseudo-)interval variables
* ------------------------------------------------------------------------------

	use "$posted/workingdata.dta", clear
	
*** Harmonize N samples
	local vlist ses, gender, age, igrade, immig
	foreach dv in S_OSLmath S_OSLlang S_CC S_PT {
		gen sample_`dv' =! missing(`dv', `vlist')
		distinct SCHOOLID if sample_`dv'
	}
	
*** Set PVMATH and PVREAD as imputed values
	gen PV0MATH100=. 
	gen PV0READ100=. 
	
	mi import wide, ///
		imputed(PV0MATH100 = PV1MATH100 PV2MATH100 PV3MATH100 PV4MATH100 PV5MATH100 ///
				PV0READ100 = PV1READ100 PV2READ100 PV3READ100 PV4READ100 PV5READ100) clear
	mi describe 

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
	foreach var in S_OSLmath S_OSLlang S_PT S_CC {
		dis "`var'"
		
		// M0: Intercept only model
		mixed 	`var' [pw=wwgt54] if sample_`var'==1 		///
				|| CNT: || SCHOOLID:, pw(W_FSCHWT)  	
		est store m0_`var'

		local var_c = exp(2*[lns1_1_1]_b[_cons]) 	// var(country)
		local var_s = exp(2*[lns2_1_1]_b[_cons]) 	// var(school)
		local var_e = exp(2*[lnsig_e]_b[_cons]) 	// var(residual)

		* ICC: var(_cons)/(var(_cons)+var(_cons)+var(Residual))
		di "Country ICC:" `var_c'/(`var_c'+`var_s'+`var_e') 
		di "School ICC:" `var_s'/(`var_c'+`var_s'+`var_e')
		
		// M1
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

*** Display results
	foreach var in S_OSLmath S_OSLlang S_PT S_CC {
		esttab m0_`var' m1_`var' m2_`var' m4_`var' mfix_`var', ///
			b(%5.2f) se(%5.2f) obslast label ///
			scalars("ll Log likelihood") sfmt(%10.1f) nogap nobase nomtitle  ///
			transform(ln*: exp(2*@) 2*exp(2*@)) ///
			star(+ 0.10 * 0.05 ** 0.01 *** 0.001) indicate(country FE = *.n_CNT)
	}

* ------------------------------------------------------------------------------
*  B. Components SES 
* ------------------------------------------------------------------------------
	
	use "$posted/workingdata.dta", clear
	
	global controls gender age igrade i.immig // global controls

*** Run base model seperately for aspects of SES
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		* M1
		mixed `var' $controls paredu HST [pw=wwgt54] || CNT: || SCHOOLID: , pweight(W_FSCHWT) //m1: ri paredu + controls + HST
		mixed `var' $controls i.paredu HST [pw=wwgt54] || CNT: || SCHOOLID: , pweight(W_FSCHWT) //m1: ri i.paredu + controls + HST
		mixed `var' $controls paroccu HST [pw=wwgt54] || CNT: || SCHOOLID: , pweight(W_FSCHWT) //m1: ri paroccu + controls + HST
		mixed `var' $controls homepos HST [pw=wwgt54] || CNT: || SCHOOLID: , pweight(W_FSCHWT) //m1: ri homepos + controls + HST

		* M2
		mixed `var' $controls c.paredu##c.HST [pw=wwgt54] || CNT: paredu || SCHOOLID: , pw(W_FSCHWT) //m2: paredu##HST + controls 
		mixed `var' $controls c.paroccu##c.HST [pw=wwgt54] || CNT: paroccu || SCHOOLID: , pw(W_FSCHWT) //m2: paroccu##HST + controls
		mixed `var' $controls c.homepos##c.HST [pw=wwgt54] || CNT: homepos || SCHOOLID: , pw(W_FSCHWT) //m2: homepos##HST + controls 
	}

* ------------------------------------------------------------------------------
*  C. OUTLIER ANALYSIS 
* ------------------------------------------------------------------------------
	
	use "$posted/workingdata.dta", clear

*** Calculate DFBETAs
	global controls gender age igrade i.immig // global controls
	encode CNT, gen(s_CNT) // country number 
	
	// calculate baseline betas 
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		dis "`var'"
		mixed `var' $controls c.HST##c.ses [pw=wgt54] || CNT: ses, coeflegend
		
		gen beta_`var' = _b[c.ses#c.HST]
		gen coef_`var' = .
		gen DFbeta_`var' = .
	}
	
	// run models (excluding countries one by one - jackknife) and calculate DFBETAs
	local cntname: value label s_CNT
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		forval i = 1/54 {
			local country: label `cntname' `i'
			dis "`var' model `i', `country' is excluded"
			
			* run model
			mixed `var' $controls c.ses##c.HST [pw=wgt54] if s_CNT!=`i' || CNT: ses, iterate(10)
			
			* save coefficients and DFbetas 
			replace coef_`var' = _b[c.ses#c.HST] if s_CNT==`i'
			replace DFbeta_`var' = (coef_`var'-beta_`var')/(_se[c.ses#c.HST]) if s_CNT==`i'
		}
	}
	
	// Save DFBETAs to seperate datafile
	preserve 
		bys CNT: keep if _n == 1 
		keep CNT beta* coef* DFbeta*
		save "$posted/DFbetas.dta", replace 
	restore 

*** Graph DFBETAs 
	preserve
		bys CNT: keep if _n == 1 
		keep CNT beta* coef* DFbeta*
	
		// Define titles graphs
		local titlelist "A. Out-of-school-time lessons in mathematics" ///
			"B. Out-of-school-time lessons in language" "C. Personal tutor" ///
			"D. Commercial company lessons"
		
		// Make subgraphs
		local cvDFBETA = 2/sqrt(54) // critical value DFBETAS (check in paper)
		foreach var in D_OSLmath D_OSLlang D_PT D_CC {
			* define title
			local i = `i'+1
			local title : word `i' of "`titlelist'"
		
			* plot 
			graph bar DFbeta_`var', over(CNT, sort(1) label(angle(90) labsize(vsmall)) descending)  ///
				yline(`cvDFBETA', lp(dash) lc(black)) ///
				yline(-`cvDFBETA', lp(dash) lc(black)) ///
				ytitle("DFBETA") b1title("Country") title("`title'") ylab(#6) ///
				name(DFBETA_`var', replace) xsize(7)
		
			*graph export "$figures/DFBETA_`var'.png", name(DFBETA_`var') replace width(4000)
		}
	restore
	
*** Calculate models again (without influential cases)
	use "$posted/workingdata.dta", clear
	merge m:1 CNT using "$posted/DFbetas.dta", nogen
	global controls gender age igrade i.immig 

	// construct samples and run models on restricted samples 
	foreach var in D_OSLmath D_OSLlang D_PT D_CC {
		tab CNT if DFbeta_`var' > 2/sqrt(54) | DFbeta_`var' < -2/sqrt(54)
		gen sample2_`var' = 1 if DFbeta_`var' >= -2/sqrt(54) & DFbeta_`var' <= 2/sqrt(54)
		
		* Note: one may also want to adjust the country weights here. 
		dis "`var'"
		mixed `var' $controls c.ses##c.HST if sample2_`var' == 1 [pw=wwgt54] ///
			|| CNT: ses || SCHOOLID: , pw(W_FSCHWT) l(99) iterate(5) 
	}
	erase "$posted/DFbetas.dta"
	
	exit