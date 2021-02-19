*==============================================================================*
* Shadow education I: data preparation 
/*=============================================================================*
*-------------------------------------------------------------------------------
 Project: Zwier, D., Geven, S., & van de Werfhorst, H.G. (2021). Social inequality 
 in shadow education: The role of high-stakes testing.
 https://doi.org/10.1177/0020715220984500
 
 
 Data: The Programme for International Student Assessment (PISA) 2012 
 Stata version: 16.1
*-------------------------------------------------------------------------------

	1. Open data
	2. Recode individual-level variables 
	3. Merge with central exams (HST) and tracking information (country-level)
	4. Normalize and decompose student weights
	 
*==============================================================================*/
* 1. Open data             		   
*==============================================================================*

*** Open data
	use "$data/PISA2012_student.dta", clear 
		
*** Select variables of interest
	keep CNT SUBNATIO OECD SCHOOLID StIDStd 			///
	AGE IMMIG ST01Q01 ST04Q01 ESCS 						///
	ST55Q01 ST55Q02 ST55Q03 ST55Q04 					///
	ST57Q01 ST57Q02 ST57Q03 ST57Q04 ST57Q05 ST57Q06 	///
	PV1MATH PV2MATH PV3MATH PV4MATH PV5MATH 			///
	PV1READ PV2READ PV3READ PV4READ PV5READ 			///
	PV1SCIE PV2SCIE PV3SCIE PV4SCIE PV5SCIE 			///
	hisced hisei WEALTH CULTPOS HEDRES HOMEPOS 			///
	W_FSTUWT 
	
*==============================================================================*/
* 2. Recode individual-level variables            		   
*==============================================================================*
* ------------------------------------------------------------------------------
*  A. SES, performance and control variables 
* ------------------------------------------------------------------------------

*** Age
	recode AGE (9997/9999=.), gen(age) 

*** Gender (ST04Q01)
	recode 	ST04Q01 (2=0 "Male") (1=1 "Female") (else=.), gen(gender) 

*** Grade (ST01Q01)
	recode ST01Q01(96/99=.), gen(igrade) 		/// recode missing values

*** Ethnic background (IMMIG)
	/* Cat.: 1) non-immigrant/native students: born in country of test, 
			at least one parent born in that country
		 2) first-generation students: foreign-born students whose 
			parents are also foreign-born.
		 3) second-generation students: born in country of test, 
			parents are foreign born.*/
	recode 	IMMIG								///
		(1=0 "Native") 							///
		(3=1 "First-generation")				///
		(2=2 "Second-generation") 				///
		(9=.),									///
		gen(immig)
		
	recode 	immig (2=1), gen(d_immig) 			// recode dummy IMMIG
	lab def d_immig 0 "Native" 1 "Immigrant"
	lab val d_immig d_immig
		
*** ESCS + different components
	* scale
	recode ESCS(9997/9999=.), gen(ses)			/// recode missing values ESCS
	
	* components: hisei, hisced, WEALTH, CULTPOS HEDRES HOMEPOS
	recode hisei (9997/9999=.), 				/// recode missing values hisei
		gen(paroccu)
		
	recode hisced (9=.), 						/// recode missing values hisced
		gen(paredu)		
	
	label define paredu 						/// label paredu
		0 "None" 1 "ISCED 1" 2 "ISCED 2" 		///
		3 "ISCED 3B, C" 4 "ISCED 3A, 4" 		///
		5 "ISCED 5B" 6 "ISCED 5A, 6"
	label values paredu paredu

	/*Family wealth and possessions: 4 indices: 
		1) family wealth possessions (WEALTH) 
		2) cultural possessions (CULTPOS)
		3) home educational resources (HEDRES)
		4) home possessions (HOMEPOS): summary index of all household items, 
		also includes the variable indicating the number of books at home 
		(pp. 316, technical report) */
	recode WEALTH CULTPOS HEDRES HOMEPOS (9997/9999=.), /// recode missings
		gen(wealth cultpos hedres homepos) 

*** Performance (dividing PVs by 100)
	foreach var in 	PV1MATH PV2MATH PV3MATH PV4MATH PV5MATH /// 
					PV1READ PV2READ PV3READ PV4READ PV5READ {
		gen `var'100 = `var'/100
	}
	
* ------------------------------------------------------------------------------
*  B. Shadow education indicators  
* ------------------------------------------------------------------------------

*** Out-of-school-time lessons (ST55Q01-ST55Q04)
	* categorical variables: recode missings
	recode ST55Q01 ST55Q02 (7/9=.), gen(OSLlang OSLmath) 
	lab def OSL 1 "0 hours" 2 "0-2 hours" 3 "2-4 hours" 4 "4-6 hours" 5 "=>6 hours"
	lab val OSLlang OSLmath OSL

	* dichotomous variables
	recode ST55Q01 ST55Q02 (1=0) (2/5=1) (7/9=.), ///
		gen(D_OSLlang D_OSLmath) 
	lab def DOSL 0 "No" 1 "Yes" 
	lab val D_OSLlang D_OSLmath DOSL

	* pseudo-scale variables: midpoint method (0-2 hours = 1, 2-4 hours = 3) 
	recode ST55Q01 ST55Q02 (1=0) (2=1) (3=3) (4=5) (5=7) (7/9=.), ///
	gen(S_OSLlang S_OSLmath)
	
	* missing values OSL
	recode ST55Q01 ST55Q02 (1/6=0) (7=1) (8/9=2), gen(mOSLlang mOSLmath)
	lab def missingvalid 0 "Valid" 1 "N/A" 2 "Missing/invalid"
	lab val mOSLlang mOSLmath missingvalid

*** Out of school study time: PT, CC (ST57Q03-ST57Q04) 
	/*	HW: Homework
		GHW: Guided Homework
		PT: Personal Tutor
		CC: Commercial Company
		WP: With Parent
		COM: Computer */
	* recode missings
	recode ST57Q03 ST57Q04 (9997/9999=.), gen(PT CC) 

	* top-code scale variables GHW PT CC (cut-off point => 10)*
	recode PT CC (10/30=10), gen(S_PT S_CC) 
	
	* dichotomous variables GH, PT, CC
	recode ST57Q03 ST57Q04 (0=0) (1/30=1) (9997/9999=.), gen(D_PT D_CC) 
	lab val D_PT D_CC DOSL
	
	* missing values 
	recode ST57Q03 ST57Q04 (0/30=0) (9997=1) (9998/9999=2), gen(mPT mCC)
	lab val mPT mCC missingvalid
	
* ------------------------------------------------------------------------------
*  C. Label and save working data  
* ------------------------------------------------------------------------------

*** Keep variables of interest
	keep CNT SUBNATIO OECD SCHOOLID StIDStd 			///
	age gender igrade immig d_immig ses paroccu paredu 	///
	wealth cultpos hedres homepos						///
	PV*MATH100 PV*READ100								///
	OSLlang OSLmath  									///
	D_OSLlang D_OSLmath S_OSLlang S_OSLmath 	 		///
	mOSLlang mOSLmath mPT mCC							///
	PT CC S_PT S_CC D_PT D_CC							///
	W_FSTUWT 
	
*** Label variables
	lab var age 		"Age of student"
	lab var gender		"Gender (female = 1)"
	lab var igrade 		"International grade"
	lab var immig 		"Ethnic background"
	lab var d_immig		"Ethnic background (dummy)"
	lab var ses 		"SES (ESCS-index)"
	lab var paroccu 	"Highest parental occupation"
	lab var paredu		"Highest parental education"
	lab var wealth 		"Family wealth possessions"
	lab var cultpos 	"Cultural possessions"
	lab var hedres 		"Home educational resources"
	lab var homepos 	"Summary index of all household items"
	
	lab var PV1MATH100	"PV1 mathematics"
	lab var PV2MATH100	"PV2 mathematics"
	lab var PV3MATH100	"PV3 mathematics"
	lab var PV4MATH100	"PV4 mathematics"
	lab var PV5MATH100	"PV5 mathematics"
	lab var PV1READ100	"PV1 reading"
	lab var PV2READ100	"PV2 reading"
	lab var PV3READ100	"PV3 reading"
	lab var PV4READ100	"PV4 reading"
	lab var PV5READ100	"PV5 reading"
	
	lab var OSLlang		"OSL language (categories)"
	lab var D_OSLlang	"OSL language (dummy)"
	lab var S_OSLlang	"OSL language (scale)"
	lab var OSLmath		"OSL mathematics (categories)"
	lab var D_OSLmath	"OSL mathematics (dummy)"
	lab var S_OSLmath	"OSL mathematics (scale)"
	lab var mOSLlang	"Missing values OSL language"
	lab var mOSLmath 	"Missing values OSL math"
	
	lab var PT			"Out-of-school study time: personal tutor"
	lab var CC			"Out-of-school study time: commercial company"
	lab var	S_PT		"Personal tutor (scale)"
	lab var S_CC		"Commercial company (scale)"
	lab var	D_PT		"Personal tutor (dummy)"
	lab var D_CC		"Commercial company (dummy)"
	lab var mPT			"Missing values personal tutor"
	lab var mCC 		"Missing values commercial company"
	
*==============================================================================*/
* 3. Merge with central exams (HST) and tracking information (country-level)
*==============================================================================*

	egen n_CNT = group(CNT) 	// country number instead of abbreviations
	tabdisp CNT, cell(n_CNT) 	// overview country numbers and abbreviations
	
*** Merge with country-level data
	/* We derived this indicator from previous research (Bishop, 1997; Bol, Witschge, 
	Van de Werfhorst, & Dronkers, 2014; Fuchs & Wößmann, 2007; Wößmann, 2003; 
	Wößmann, Luedemann, Schuetz, & West, 2009) and supplement and update it with 
	other data sources (EACEA/Eurydice, 2009, 2015; EP-Nuffic, 2015; OECD, 2008, 
	2012, 2013c; UNESCO-IBE, 2012). In four countries, there are no nationally-
	centralized sexaminations. These countries score 0.81, 0.51, 0.44 and 0.09
	representing the proportion of subnational regions where these HSTs 
	examinations are present (see Bol et al., 2014; Wößmann et al., 2009 for a 
	similar approach).
	
	Tracking age is retreived from OECD (2013). 2. Selecting and grouping students. 
	In PISA 2012 Results: What Makes Schools Successful? Resources, Policies, 
	and Practices.: Vol. IV (pp. 155–181). https://doi.org/10.1787/9789264267510-9-en
	*/
	preserve
		// import country data
		import excel "$data/countrydata.xls", sheet("data") firstrow clear
		drop A
		rename (tracks15y_2012 selage_2012) (tracks15y selage)
		
		// mean-standardize age of selection and #tracks
		foreach var in tracks15y selage {
			sum `var'
			gen c_`var' = `var' - r(mean)
		}
		
		tempfile cntdata
		save `cntdata'
	restore
	merge m:1 CNT using `cntdata' 
		
*** Drop countries with missing values: ALB(1), ARE(2), COL(12), KAZ(33), LIE(35), 
	* MAC(39), QAT(49), QCN(50), QRS(51), SRB(55), TUN(61)
	table CNT if _merge==1
	drop if _merge==1 | tracks15y ==.
	drop n_CNT _merge

*** Label variables
	egen n_CNT = group(CNT) // new var country number (countries final sample)
	lab var n_CNT 		"Country number"
	lab var tracks15y 	"Number of tracks"
	lab var c_tracks15y "Number of tracks (centralized)"
	lab var selage 		"Tracking age"
	lab var c_selage 	"Tracking age (centralized)"
		
*** Table 1 is based on these data
	tabdisp CNT, cell(n_CNT HST selage)

*==============================================================================*/
* 4. Normalize and decompose student weights					   			   *
*==============================================================================*
	/* See Annex A9: SPSS SYNTAX to prepare data file for multilevel regression 
	analysis (PISA 2006: Science Competencies for Tomorrow’s World, Vol. 1, 2007)
	> Compute normalized student weights, p. 18
	
	See Pisa Data Analysis Manual (2009), p. 219: 
	formula normalized student weights: (W_FSTUWT * TSS) / (WNSS * #countries)
	*/

*** Normalized students weights
	* create variable for national sample size country (_N, NSS)
	bys CNT: gen NSS=_N 
	
	* create variable for weighted sample size country (WNSS)
	bys CNT: egen WNSS=total(W_FSTUWT)
	
	* wgt= (W_FSTUWT/WNS)*_N or W_FSTUWT*NSS/WNSS (same formula)
	bys CNT: gen wgt= (W_FSTUWT/WNSS)*NSS
	
	* create variable for total sample size (TSS)
	gen TSS=_N 
	
	* country factor: the smaller the country's sample size, the larger this weight
	gen cntfac54=(TSS/54)/NSS
	
	* standardised student weights: wgt * country factor. 
	gen wgt54=wgt*cntfac54
	
*** Normalized within student weights
	* merge file with school-level weights
	preserve
		tempfile schoolweights 
		use "$data/PISA2012_school.dta", clear 	// open school data

		keep CNT SCHOOLID W_FSCHWT 				// select weight var
		save `schoolweights'					
	restore 
	
	merge m:1 CNT SCHOOLID using `schoolweights'
	keep if _merge == 3

	* decompose weights
	gen wschoolweight = (W_FSTUWT/W_FSCHWT)
	bys CNT: egen WNSS2 = total(wschoolweight) 
	bys CNT: gen wgt2 = (wschoolweight / WNSS2) * NSS
	gen wwgt54 = wgt2*cntfac54
	
	lab var wgt54 	"Normalized student weight"
	lab var wwgt54 	"Normalized within student weight"
	
	* drop aux variables 
	drop NSS WNSS WNSS2 wschoolweight wgt wgt2 TSS cntfac54 _merge

*** Save working data
	save "$posted/workingdata.dta", replace

	exit // end do-file