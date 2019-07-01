# SAS Class Projects 
A small showcase of some of the projects and concepts learned throughout my SAS Programming courses at NC State University. 
## Census Housing Data Project
An assigned project to test the students' understanding of how to transpose data through different methods, join datasets using PROC SQL, and create more dynamic code utilizing macros.Additionally we created a specialized template to plot histograms and boxplots of the finalized dataset. 
### Data
The data used for this project were edited datasets extracted from IPUMS. Their format and generalized values will be described here with some clarification of which variables were chosen for extraction. 
<br>
<br>
IPUMS 2005 Values.txt -- This file contains information from the 2005 Census focusing on the First Mortgage Monthly Payment, Household Income, and House Value for each individual indicated by a serial number.
<br>
<br>
st555.demographics -- This dataset contains State, Metro, and Ownership information about the individual indicated by a serial number.
<br>
<br>
st446.amounts, st446.amountsdesc, st446.alldata, st446.alldatadesc -- These datasets were given to us as a means of comparing our results to the professor's.
<br>
<br>
Citation:  
Steven Ruggles, Sarah Flood, Ronald Goeken, Josiah Grover, Erin Meyer, Jose Pacas and Matthew Sobek. IPUMS USA: Version 9.0 [dataset]. Minneapolis, MN: IPUMS, 2019. https://doi.org/10.18128/D010.V9.0
### Code Documentation 
**Reading in the Data:**
Setting up a macro for the number of category to value pairings so that the code can be adjusted easily for future use. 
```sas 
%let pair = 3;
```
Usage of the DATA step and different forms of input to handle the .txt file's format. 
```
         2 Mortgage Payment        $0  Household Income   $12,000Home Value$9,999,999
         3 Mortgage Payment        $0  Household Income   $17,800Home Value$9,999,999
         4 Mortgage Payment      $900  Household Income  $185,000Home Value  $137,500
 ```
