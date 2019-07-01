# SAS Class Projects 
A small showcase of some of the projects and concepts learned throughout my SAS Programming courses at NC State University. 
## Census Housing Data Project
An assigned project to test the students' understanding of how to transpose data through different methods, join datasets using PROC SQL, and create more dynamic code utilizing macros. Additionally we created a specialized template to plot histograms and boxplots of the finalized dataset. 
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
Usage of the DATA step and different forms of input to handle the IPUMS 2005 Values.txt file's format. A portion of that format is shown below. 
```
         2 Mortgage Payment        $0  Household Income   $12,000Home Value$9,999,999
         3 Mortgage Payment        $0  Household Income   $17,800Home Value$9,999,999
         4 Mortgage Payment      $900  Household Income  $185,000Home Value  $137,500
 ```
 The file is read in as compare.amounts.
 ```sas
 data compare.amounts(keep = serial category value);
    infile ipums;
    input Serial    1-10
        category1   $ 12-27
        value1      comma10.
        category2   $ 40-55
        value2      comma10.
        category3   $ 66-75
        value3      comma10. ;
```
Arrays are used to cycle through the rows of data and transpose it as the file is read in to SAS. *If the value is 9999999 and the category is Home Value then the actual value is missing.* 
```sas
array categ[&pair] $ category:;
    array val[&pair] value:;
    do i = 1 to dim(val);
        Category = categ[i];
        if val[i] = 9999999 and categ[i] = 'Home Value' then val[i] = .;
        Value = val[i];
        output;
    end;
run;
```
**Transposing and Joining:**
The demographics dataset needed to be transposed using [PROC TRANSPOSE](https://documentation.sas.com/?docsetId=proc&docsetTarget=n1xno5xgs39b70n0zydov0owajj8.htm&docsetVersion=9.4&locale=en) so that it could be joined to the compare.amounts dataset. 
```sas
proc transpose data= st555.demographics out= compare.demog;
    by Serial;
    id source;
    var value;
run;
```
Joining both datasets using [PROC SQL](https://documentation.sas.com/?docsetId=sqlproc&docsetTarget=p12ohgh32ffm6un13s7l2d5p9c8y.htm&docsetVersion=9.4&locale=en) to make the compare.alldata dataset. Their common variable is their Serial Number given to each household. 
```sas
proc sql;
    create table compare.alldata as
    select d.serial, d.state, d.metro, d.ownership, a.category, a.value
    from compare.amounts as a left join compare.demog as d on a.serial=d.serial
    order by state, metro, ownership, serial, category, value;
quit;
```
