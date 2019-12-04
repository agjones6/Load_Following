%% Fitting demand curves using statistical methods
% 
% The demand curve data comes from eia. It was downloaded using python 

%% Importing the data
my_Path = "/Users/AndyJones/Documents/GitHub/master_proj";
my_Dir = "/Grid_Information/Curve_Fitting/*.csv";
my_Files = dir(my_Path + my_Dir);

my_csv = strcat(my_Files.folder,"/",my_Files.name);

raw_data = importdata(my_csv);


% string(my_Files.folder) + string(my_Files.name)





