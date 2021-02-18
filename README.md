# Social inequality in shadow education: The role of high-stakes testing
Replication files to Zwier, D., Geven, S., &amp; van de Werfhorst, H. G. (2021). Social inequality in shadow education: The role of high-stakes testing. International Journal of Comparative Sociology. https://doi.org/10.1177/0020715220984500

### Follow these steps to replicate the results:
1. Clone this github repository or download and unzip "SEinequality.zip".
2. Download the PISA 2012 (a) "Student questionnaire data file" and (b) "School questionnaire data file" [here](https://www.oecd.org/pisa/data/pisa2012database-downloadabledata.htm).
3. Save the PISA 2012 data in Stata (.dta) format in the [01_data](/01_data) folder. Rename the student questionnaire data to "PISA2012_student.dta" and the school questionnaire to "PISA2012_school.dta".
4. Customize the path for the global macro "dir" in [MASTER.do](MASTER.do) (line 19) and run this do-file. This do-file will run the do-files [01_dataprep.do](01_dataprep.do) and [02_analysis.do](02_analysis.do). Output will be exported to folders [03_figures](/03_figures) and [04_tables](/04_tables).

The main robustness checks that are reported on in the article can be found in [03_robustness.do](03_robustness.do).