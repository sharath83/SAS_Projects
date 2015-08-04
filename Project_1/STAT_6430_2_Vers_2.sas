* Group 2;
* Project 1;
* Importing Aqua dataset;

*Setting the filename path and name for use throughout the program;

FILENAME aqua 'C:\Users\Jason\Desktop\MyLife\UVA\STAT_6430\SAS_Class\Projects\Project_1\aquastat.csv';
FILENAME pop 'C:\Users\Jason\Desktop\MyLife\UVA\STAT_6430\SAS_Class\Projects\Project_1\Data_Extract_From_World_Development_Indicators_Data.txt';

/*
Problem 1) Import and prepare the water data.

Problem 1.A) Import the aquasstat.csv data into SAS. If you use the import wizard make sure to include
the generated PROC IMPORT code in your program.

Problem 1.B) Only keep variables corresponding to country name, global region, agricultural withdrawl,
industrial withdrawl, municipal withdrawl, and total withdrawl. After this step your dataset 
should have six variables.

Problem 1.C) Make sure each variable has an appropriate type, format, name, and label.

*/

*Importing the aquastat.csv file using the above FILENAME convention. The DMBS is set to csv, we 
are not importing the names, and the import procedure starts are row 2.;

Proc Import Datafile = Aqua
		Out = AquaUsage
		Dbms = csv
		Replace;
		Getnames = No;
		Datarows = 2;
Run;

*Checking the initial contents of the Aqua dataset;

Proc Contents Data = AquaUsage Position; /* Check the Variables*/
Run;

*Select the necessary variables and rename them to something more informative, throwing out unnescesary variables;
*setting the Obs in the set portion to 200 because the remainder of the dataset of aquastat.csv is metadata and uncessary for this portion;
DATA AquaUsage (RENAME = (Var2 = Country_Name 
				          Var3 = Global_Region 
						  Var5 = Agr_Withdrawl 
						  Var9 = Ind_Withdrawl 
                          Var13 = Muni_Withdrawl 
                          Var17 = Total_Withdrawl));
	SET Work.AquaUsage (KEEP = Var2 Var3 Var5 Var9 Var13 Var17 Obs = 200);
RUN;
*Set appropriate labels and providing each variable with more information regarding what they do;
DATA AquaUsage (LABEL = "Water Consumption Data");
	SET Work.AquaUsage;
	LABEL Country_Name = "Country Name"
		  Global_Region = "Global Region"
		  Agr_Withdrawl = "Agricultural Water Consumption in Bil. cum"
		  Ind_Withdrawl = "Industrial Water Consumption in Bil. cum"
		  Muni_Withdrawl = "Muncipal Water Consumption in Bil. cum"
		  Total_Withdrawl = "Total Water Consumption in Bil. cum"
		;

TITLE "Water Usage Statistics of Countries";

*Confirming the contents of the formatted AquaUsage dataset;
PROC PRINT AquaUsage;
	TITLE = 'AquaUsage Testing';
RUN;

PROC CONTENTS DATA = AquaUsage;
PROC PRINT DATA = AquaUsage (FIRSTOBS=200);
RUN;

/* Question 2) Import and prepare population data.

Question 2.A) Impor the population data into SAS

*/

*A. Importing and Preparing Population Data;
PROC IMPORT DATAFILE = Pop
			OUT = PopStat_raw
			DBMS = TAB
			REPLACE;
			GUESSINGROWS = 4090; *It allows SAS to effectively determine the lengths and datatypes of each variable;
RUN;

/*Data PopStat;
	Length Series_Name $40 Series_Code $14
		Country_Name $30 Country_Code $3
		Value 18;
	Infile Pop DLM = "09"X;
	Input Series_Name $ Series_Code $
		Country_Name $ Country_Code $
		Value;
Run;*/
PROC PRINT DATA = PopStat_raw (FIRSTOBS = 4080);
RUN;

*B. Only keep GDP, GDP per capita, Agriculture value added, and total population.;
DATA PopStat;
	SET Work.PopStat_raw (OBS = 4085 WHERE = (Series_Code IN ("SP.POP.TOTL", 
												"NV.AGR.TOTL.ZS", 
												"NY.GDP.MKTP.CD", 
												"NY.GDP.PCAP.CD")));
Run;
							
PROC CONTENTS DATA = PopStat POSITION;
RUN;

*C Keep only name of the statistic, the country name, the country code, and the value of the statistic;
DATA PopStat (RENAME = (_2014__YR2014_ = Value));
	SET Work.PopStat (DROP = Series_Name);
RUN;
*Change the Value = ".." to zero;
*Change the Value datatype to Numeric and Put it into StatValue;
DATA PopStat (DROP = Value);
	SET Work.PopStat;
	IF Value EQ ".." THEN Value = "0";
	StatValue = Input(Value, 17.);
RUN;
PROC PRINT DATA = PopStat (FIRSTOBS = 850);
RUN;
	
*D Transposing the Data;
* First we need to sort the data by Country Name and Code;
PROC SORT DATA = PopStat;
	BY Country_Name Country_Code;
RUN;
* We want to transpose the data;
* BY country name - Want to have one record per value in the final data set;
* ID Series_Code - We need all the statistics as our new varibales;
* VAR _2014__YR2014_ - Value of the statistic which we actually want to transpose;

PROC TRANSPOSE DATA = PopStat OUT = PopStat;
   BY Country_Name 
      Country_Code;
   ID Series_Code;
   VAR StatValue;
RUN; *215 Observations recorded;

TITLE "Population Statistics of Countries - Transposed";
PROC PRINT DATA = PopStat(FIRSTOBS = 200);
RUN;
PROC CONTENTS DATA = PopStat; *Check the contents;
RUN;
/*Change the Datatype and Format the Dataset;
Data PopStat (Drop = SP_POP_TOTL 
				NV_AGR_TOTL_ZS 
				NY_GDP_MKTP_CD 
				NY_GDP_PCAP_CD) ;

	Set Work.PopStat (Drop = _NAME_);
*Change the datatype and format;
	Total_Population = Input(SP_POP_TOTL, Comma16.);
	ValueAdd_Agri = Input(NV_AGR_TOTL_ZS, Percent7.2);
	GDP = Input(NY_GDP_MKTP_CD, Dollar16.2);
	Percapita_Income = Input(NY_GDP_PCAP_CD, Dollar16.2);			
Run;*/
*Rename and Format Population Statistics;
DATA PopStat (RENAME = (SP_POP_TOTL = Total_Population 
                        NV_AGR_TOTL_ZS = ValueAdd_Agri
						NY_GDP_MKTP_CD = GDP 
                        NY_GDP_PCAP_CD = Percapita_Income));
	SET Work.PopStat (DROP = _NAME_);
	FORMAT NV_AGR_TOTL_ZS 17.2
		   NY_GDP_PCAP_CD Dollar17.2
		   NY_GDP_MKTP_CD Dollar17.2
		   SP_POP_TOTL Comma17.;
*Labels can be added here;
RUN;

TITLE "Population Statistics of Countries - Final Formatted";
PROC PRINT DATA = PopStat(Firstobs = 200);
RUN;

*Q3. Combine the water and population datasets to create a single SAS dataset;

/*
Problem 3) Combine the water and population datasets to create a single SAS dataset that has one row per country.
There should be 11 variables: country name, country code, global region, agricultural withdrawl,
industrial withdrawl, municipal withdrawl, total withdrawl, GDP, GDP per capita, agriculture value added,
and total population.

*/

PROC SORT DATA=AquaUsage;
	BY Country_Name;
RUN;

PROC SORT DATA=PopStat;
	BY Country_Name;
RUN;

DATA combined_countries;
	MERGE AquaUsage PopStat;
	BY Country_Name;
RUN;

PROC PRINT DATA=combined_countries;
	TITLE 'Combined Country Data';
RUN;

/*

PROBLEM 3.A) Print out the names of countries in the water dataset that did not match any country in the 
population dataset.

*/
PROC CONTENTS DATA = AquaUsage(OBS = 5);
RUN;

/*First we need to ensure that each dataset is sorted individually by the Country_Name variable

*/

PROC SORT DATA=AquaUsage;
	BY Country_Name;
RUN;

PROC SORT DATA=PopStat;
	BY Country_Name;
RUN;

/*

The portion below is identifying Country Names in the AquaUsage dataset that was not an exact match
for names in the PopStat dataset. Please note that there are countries listed that are actually in both datasets,
but due to different naming conventions, they are not actually the same. For instance, the Country Egypt is Present in 
the AquaUsage dataset as Egypt, but in the PopStat dataset it is listed as Arab Repbulic of Egypt, so it does not present
an exact match. There are several other examples of this. What the IF statement says is if the Country is not present then 
add it to the cntry_notinpop dataset.

*/

DATA cntry_notinpop;
	MERGE AquaUsage (IN=inAQ) PopStat (IN=inPOP);
	PUTLOG _N_ inAQ inPOP;
	BY Country_Name;
	IF inPOP EQ 0 THEN OUTPUT cntry_notinpop;
RUN;

PROC PRINT DATA=cntry_notinpop;
	TITLE 'Countries in Aqua Data but not in Population Data';
RUN;

/*

Problem 3.B) Print out the names of coutnries in the population dataset that did not match any country 
in the water dataset. 

To do this, we are going to do a very similar procedure as above, but this time the IF statement will 
include IF inAQ EQ 0 THEN OUTPUT cntry_notinaqua

*/

DATA cntry_notinaqua;
	MERGE AquaUsage (IN=inAQ) PopStat (IN=inPOP);
	PUTLOG _N_ inAQ inPOP;
	BY Country_Name;
	IF inAQ EQ 0 THEN OUTPUT cntry_notinaqua;
RUN;

PROC PRINT DATA=cntry_notinaqua;
	TITLE 'Countries in Population Dataset but not in Aqua Dataset';
RUN;

/*

PROBLEM 3.C) Don't worry about the other countries, but make sure that American Has the same name in both
datasets then run the merge again. 








