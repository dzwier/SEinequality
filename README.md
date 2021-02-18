# Social inequality in shadow education: The role of high-stakes testing
Replication files to the article Zwier, D., Geven, S., &amp; van de Werfhorst, H. G. (2021). Social inequality in shadow education: The role of high-stakes testing. International Journal of Comparative Sociology. https://doi.org/10.1177/0020715220984500

To replicate the results presented in the paper, clone this repository or download and upack this zip-archive and run the code. Before you run the code, you have to download the PISA 2012 (a) "Student questionnaire data file" and (b) "School questionnaire data file" via https://www.oecd.org/pisa/data/pisa2012database-downloadabledata.htm. 

Follow these steps to replicate the results:
1. Unzip "ZwierGevenvandeWerfhorst_2021.zip"
2. Store the PISA 2012 data in Stata (.dta) format in the folder "00_data.do".Rename the student questionnaire data to "PISA2012_student.dta" and rename the school questionnaire to "PISA2012_school.dta".
3. Customize the path for the global macro "dir" and run the do-file "MASTER.do". This do-file will run the do-files "01_dataprep.do" and "02_analysis.do". 
4. Robustness checks that are reported on in the article can be found in "03_robustness.do".