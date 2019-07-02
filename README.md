# SAS Class Projects 
A small showcase of some of the projects and concepts learned throughout my SAS Programming courses at NC State University. 
## Census Housing Data Project
An assigned project to test the students' understanding of how to transpose data through different methods, join datasets using PROC SQL, and create more dynamic code utilizing macros. Additionally we created a specialized template to plot histograms and boxplots of the finalized dataset. 
### Data
The data used for this project were edited datasets extracted from IPUMS. Their format and generalized values will be described here with some clarification of which variables were chosen for extraction. 
<br>
<br>
**IPUMS 2005 Values.txt** -- This file contains information from the 2005 Census focusing on the First Mortgage Monthly Payment, Household Income, and House Value for each individual indicated by a serial number.
<br>
<br>
**Class.demographics** -- This dataset contains State, Metro, and Ownership information about the individual indicated by a serial number.
<br>
<br>
**Class.amounts, Class.amountsdesc, Class.alldata, Class.alldatadesc** -- These datasets were given to us as a means of comparing our results to the professor's.
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
proc transpose data= Class.demographics out= compare.demog;
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
To make a report that only gives the households from certain states, a macro variable was used so that the report could be easily changed. The footnote will list the states included, which requires the use of a macro function so that they are listed correctly. 
```sas
%let state = "Alabama" "Alaska";   

options orientation = landscape nodate;

title "State-Level Listing of Income and Mortgage-Related Values";

footnote J = l height = 8pt "States included: %sysfunc(compress(&state, '""'))";
```
The report is created using [PROC REPORT](https://documentation.sas.com/?docsetId=proc&docsetTarget=n1dz7jdasx5t56n1rmlx346dyk6n.htm&docsetVersion=9.4&locale=en) and saved as a pdf.
```sas
ods pdf file = "&Compare/State-Level Report.pdf" columns = 2 style= Sapphire;

proc report data = compare.alldata ;
    column state metro ownership serial category value;
    where state in(&state);
    define state / "State" order;
    define metro / "Metro Status" order;
    define ownership / "Ownership Status" order;
    define serial / "Household ID" order;
    define category / "Category" order;
    define value / "Amount" format = dollar10. display ;
run;

ods pdf close;

title;

footnote;
```
One part of the project was to make histograms and boxplots for Mortgage Payment, Household Income, and Home Value in a particular format. The compare.amounts dataset needed to be transposed in order for this to work. 
```sas
proc transpose data = compare.amounts out = compare.ipums(drop = _NAME_);
    by Serial;
    id category;
    var value;
run;
```
As part of the plots, the median value was expected to be displayed next to the histograms. Using PROC SQL we were able to calculate the median for each variable and create macro variables for those values.
```sas
proc sql;
    select distinct(translate(strip(category), "_", " "))
    into :category1-:category3
    from compare.alldata;
    select median(value)
    into :median1-:median3
    from compare.alldata
    group by category;
quit;

%let year = 2005;
```
To format the histograms and boxplots we created a custom template using [PROC TEMPLATE](https://documentation.sas.com/?docsetId=odsproc&docsetTarget=p1wzeog1t945ntn1i44ymy4t26uc.htm&docsetVersion=9.4&locale=en) and produced the final image using [PROC SGRENDER](https://documentation.sas.com/?docsetId=grstatproc&docsetTarget=n194gmpu73h4t5n1vavyo656yj71.htm&docsetVersion=9.4&locale=en). 
```sas
proc template;
    define statgraph gtl.histograph;
        begingraph;
            entrytitle "Distributions of %sysfunc(compress(&category1, "_")), %sysfunc(compress(&category2, "_")), and %sysfunc(compress(&category3, "_"))";
            entrytitle "Based on the &year Census";
            layout lattice / columns = 3 rows = 2
                            columngutter = 1
                            rowgutter = 1
                            rowweights = (.8 .2)
                            columndatarange = union
                            ;
                columnaxes;
                    columnaxis / Label = "%sysfunc(compress(&category1, "_"))";
                    columnaxis / Label = "%sysfunc(compress(&category2, "_"))";
                    columnaxis / Label = "%sysfunc(compress(&category3, "_"))";
                endcolumnaxes;
                layout overlay / yaxisopts = (Label = "Median Value is &median1");
                    histogram &category1 ;
                endlayout;
                layout overlay / yaxisopts = (Label = "Median Value is &median2");
                    histogram &category2 ;
                endlayout;
                layout overlay / yaxisopts = (Label = "Median Value is &median3");
                    histogram &category3 ;
                endlayout;
                layout overlay;
                    boxplot y = &category1 / orient = horizontal;
                endlayout;
                layout overlay;
                    boxplot y = &category2 / orient = horizontal;
                endlayout;
                layout overlay;
                    boxplot y = &category3 / orient = horizontal;
                endlayout;
            endlayout;
        endgraph;
    end;
run;

ods listing gpath = "&Compare\" dpi=300;

ods graphics on /imagename= "HistoBoxes" width = 6in height = 4.5in outputfmt = png reset = index;

proc sgrender data= compare.ipums template = gtl.Histograph;
run;

ods graphics off;

ods listing close;
```
As a way of checking our work, description portions to the compare.amounts and compare.alldata datasets were made to be compared to the professor's own datasets. [PROC DATASETS](https://documentation.sas.com/?docsetId=proc&docsetTarget=p0xdkenol7pi1cn14p0iq38shax4.htm&docsetVersion=9.4&locale=en) was used to make the descriptions and [PROC COMPARE](https://documentation.sas.com/?docsetId=proc&docsetTarget=n0c1y14wyd3u7yn1dmfcpaejllsn.htm&docsetVersion=9.4&locale=en) to compare our group's final datasets and the professor's. 
```sas
%let options = outbase outcompare outdiff outnoequal method = absolute criterion = 1E-6 noprint;

%let keep = memname varnum name type length; 


ods output position = compare.alldatadesc;

proc datasets nolist;
    contents data = compare.alldata varnum out=alldatadesc(KEEP = &keep);    
    run;
quit;

ods output close;

ods output position = Compare.amountsdesc;

proc datasets nolist;
    contents data = compare.amounts varnum out=alldatadesc(KEEP = &keep);    
    run;
quit;

ods output close;




proc compare base = Class.amounts
    compare = compare.amounts
    out = compare.diff1a
    &options ;
run;

proc compare base = Class.alldata
    compare = compare.alldata
    out = compare.diff1b
    &options ;
run;

proc compare base = Class.amountsdesc
    compare = compare.amountsdesc
    out = compare.diff2a
   &options ;
run;

proc compare base = Class.alldatadesc
    compare = compare.alldatadesc
    out = compare.diff2b
    &options ;
run;

quit;








