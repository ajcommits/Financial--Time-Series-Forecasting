*Reading in Data;
data vix;
	infile '/home/u48908401/sasuser.v94/Vix_Final.csv' firstobs=2 dsd missover;
	input date : mmddyy10. vol obs;
	format date ddmmyy10.;
	vol_log = log(vol);
run;

title "Univariate Analysis";
proc univariate data = vix;
  histogram vol_log / normal kernel;
  inset mean std normal / position = ne;
run;
title;

proc sgplot data = vix;
  series x = date y = vol;
run;

*looking for stationarity using Dickey Fuller test;
proc arima data = vix;
identify var = vol_log(1) stationarity=(adf=1);
run;

*Fitting a differenced model;
proc arima data = vix;
/* identify var = vol; */
/* identify var = vol_log; */
identify var = vol_log(1);
estimate q = (1);
estimate q = (1,2);
estimate q = (1,2,6);
estimate q = (1,2,6,8);
estimate q = (1,2,6,8,10);
forecast lead = 20 id = date out =out1;
outlier;
run;

*Plotting Log volatility vs forecasted Log vols;
proc sgplot data = work.out1;
band x =date lower = l95 upper = u95/
legendlabel="95% Forecast Band" fillattrs=graphconfidence
			transparency=0.5 fill outline; 
series x = date y = vol_log / markers;
series x = date y = forecast / lineattrs=graphdata2;
run;

proc transreg data = vix;
model boxcox(vol) = identity(date);
run;

*Dataset made fror plotting volatility and Forecasted volatility;
data plot;
set out1;
y=exp(vol_log);
l95=exp( l95 );
u95=exp( u95 );
forecast = exp(forecast+ std*std/ 2 );
obs = _N_;
if _N_ > 980 ; *Number from where you would like to see the graph;
run ;

proc sgplot data =plot noautolegend ;
scatter x = obs y =forecast / yerrorlower =L95 yerrorupper =U95;
series x = obs y =forecast;
yaxis label = 'Forecasted Volatility' ;
xaxis label = 'Obsv number' ;
Run ;


data plot;
set plot;
label Forecast ="Vix price"
L95 = "Lower 95% confidence limit"
U95 = "Upper 95% confidence limit"
;
run;
proc report data=plot;
title1 "Table of Forecasted Vix values";
column Forecast L95 U95;
define forecast / order;
run;

data plot2;
   merge plot vix_test;
   by date;
   format date ddmmyy10.;
run;

proc sgplot data =plot2 ;
	band x =date lower = l95 upper = u95;
	scatter x = date y =vol ;
	*series x = date y =vol;
	series x = date y =forecasted;
	yaxis label = 'Forecasted Volatility' ;
	xaxis label = 'Time' ;
Run ;
