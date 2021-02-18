*==============================================================================*
*       Shadow education : master do-file          							   *
/*=============================================================================*
*-------------------------------------------------------------------------------
 Project: Zwier, D., Geven, S., & van de Werfhorst, H.G. (2021). Social inequality 
 in shadow education: The role of high-stakes testing.
 
 
 Data: The Programme for International Student Assessment (PISA) 2012 
 Last edited 19-11-2020
 Stata version: 16.1
*-------------------------------------------------------------------------------
	 
*==============================================================================*/
* 0. Paths and settings           
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
* 1. Run do-files       
*==============================================================================*

	do "$dofiles/01_dataprep.do"
	do "$dofiles/01_analysis.do"


