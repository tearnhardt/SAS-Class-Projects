/*
* This program produces a specified-by-state(s) report and general histograms 
* on Census housing data from IPUMS.
* 
* Authors: Taylor Earnhardt, Aaron Barlowe, Lingchao Mao
*
*/


*Setting up directories;

%let ST555 = L:\St555; 

%let Compare = S:\Desktop\ST446\Project 2;

%let ST446 = L:\ST446\MP#2;


x "cd &ST555";

*This is the file that contains the information on Mortgage Payments, Household Income, and the House Value;
filename ipums "&ST555\IPUMS 2005 Values.txt"; 

libname compare "&Compare";

libname st555 "&ST555";

libname st446 "&ST446";

x "cd &Compare";



*Setting program wide system options;


ods listing close;



*Creating additional macro variables;

%let pair = 3;


*Reading in the IPUMS dataset;

data compare.amounts(keep = serial category value);
    infile ipums;
    input Serial    1-10
        category1   $ 12-27
        value1      comma10.
        category2   $ 40-55
        value2      comma10.
        category3   $ 66-75
        value3      comma10. ;
    array categ[&pair] $ category:;
    array val[&pair] value:;
    do i = 1 to dim(val);
        Category = categ[i];
        if val[i] = 9999999 and categ[i] = 'Home Value' then val[i] = .;
        Value = val[i];
        output;
    end;
run;


*Transposing demographics data to be used in the next step;

proc transpose data= st555.demographics out= compare.demog;
    by Serial;
    id source;
    var value;
run;



*Creating joint data set with demographics data call Alldata;

proc sql;
    create table compare.alldata as
    select d.serial, d.state, d.metro, d.ownership, a.category, a.value
    from compare.amounts as a left join compare.demog as d on a.serial=d.serial
    order by state, metro, ownership, serial, category, value;
quit;



*Create macro variables for the report;
    *this macro can be changed to get different reports for different states;
    
%let state = "Alabama" "Alaska";    



*Preparing the state report options;

options orientation = landscape nodate;

title "State-Level Listing of Income and Mortgage-Related Values";

footnote J = l height = 8pt "States included: %sysfunc(compress(&state, '""'))";


*Creating and outputing the state report;

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


*Transpose data for the histogram;

proc transpose data = compare.amounts out = compare.ipums(drop = _NAME_);
    by Serial;
    id category;
    var value;
run;



*Create macro variables and calculate medians for the histogram;

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



*Create custom template;

proc template;
    define statgraph gtl.histograph;
        begingraph;
            entrytitle "Distributions of %sysfunc(compress(&category1, “_”)), %sysfunc(compress(&category2, “_”)), and %sysfunc(compress(&category3, “_”))";
            entrytitle "Based on the &year Census";
            layout lattice / columns = 3 rows = 2
                            columngutter = 1
                            rowgutter = 1
                            rowweights = (.8 .2)
                            columndatarange = union
                            ;
                columnaxes;
                    columnaxis / Label = "%sysfunc(compress(&category1, “_”))";
                    columnaxis / Label = "%sysfunc(compress(&category2, “_”))";
                    columnaxis / Label = "%sysfunc(compress(&category3, “_”))";
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



*Set options for the graph;

ods listing gpath = "&Compare\" dpi=300;

ods graphics on /imagename= "HistoBoxes" width = 6in height = 4.5in outputfmt = png reset = index;



*Use custom template on data;

proc sgrender data= compare.ipums template = gtl.Histograph;
run;

ods graphics off;

ods listing close;



*Description portions of Amounts and Alldata;

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


*Comparisons between datasets;

proc compare base = st446.amounts
    compare = compare.amounts
    out = compare.diff1a
    &options ;
run;

proc compare base = st446.alldata
    compare = compare.alldata
    out = compare.diff1b
    &options ;
run;

proc compare base = st446.amountsdesc
    compare = compare.amountsdesc
    out = compare.diff2a
   &options ;
run;

proc compare base = st446.alldatadesc
    compare = compare.alldatadesc
    out = compare.diff2b
    &options ;
run;

quit;
