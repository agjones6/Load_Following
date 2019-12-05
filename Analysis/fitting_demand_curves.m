%% Fitting demand curves using statistical methods
% 
% The demand curve data comes from eia. It was downloaded using python 

%% Importing the data

% Defining the path to the current directory
% my_Path = "C:/Users/AndyJones/Documents/GitHub/master_proj"; % Mac
my_Path = "C:\Users\agjones6\Documents\GitHub\master_proj"; % Windows

% Defining the directory where the files contain demand data 
my_Dir = "/Grid_Information/Curve_Fitting/*.csv";

% Getting all of the csv files in the folder location with 
my_Files = dir(my_Path + my_Dir);

% Establishing the 

% Getting the names of the csv files
csv_names = strings(1,length(my_Files));
raw_data = cell(1,length(my_Files));
norm_data = cell(1,length(my_Files));
flat_data = cell(1,length(my_Files));
flat_time = cell(1,length(my_Files));
for i = 1:length(my_Files)
    % Putting the names of the csv's into a matrix
    csv_names(i) = strcat(my_Files(i).folder,"/",my_Files(i).name);
    
    % Getting the raw data into cell arrays
    raw_data{i} = importdata(csv_names(i))';
    
    % Getting normalized data
    norm_data{i} = raw_data{i}./max(raw_data{i},[],'ALL');
    
    % Flattening the matrix to be back to back with times = 0-23
    [num_hours,num_days] = size(norm_data{i});
    flat_data{i} = zeros(num_hours*num_days,1);
    flat_time{i} = zeros(num_hours*num_days,1);
    for i2 = 1:num_days
        st = (1+(i2-1)*num_hours);
        en = i2*num_hours;
        flat_data{i}(st:en) = norm_data{i}(:,i2);
        flat_time{i}(st:en) = (1:num_hours) - 1;
    end
end

% figure(1)
% plot(norm_data{1},'*r')
% hold on
% plot(norm_data{2},'*b')

%% Defining a function to be used to fit 
region = 2;
t_mesh = linspace(1,num_hours,500) - 1;
N = 4;
lb = -1;
ub = 1;
fun_type = "lin";

% Guessing initial values for the parameters random [-1,1]
if fun_type == "sin"
    q_guess = (ub-lb).*rand(2,N+1)+lb;
else
    q_guess = (ub-lb).*rand(1,N+1)+lb;
end


% These are the parameters found from the least squares method
if fun_type == "sin"
    q_new = fminsearch( @(q)sin_lsq(N,flat_time{region},flat_data{region},q), q_guess);
else
    q_new = fminsearch( @(q)lin_lsq(N,flat_time{region},flat_data{region},q), q_guess);
end 

% Values from the model evaluated at times from the data
if fun_type == "sin"
   model_vals = sin_fun(N,flat_time{region},q_new); 
else
    model_vals = lin_fun(N,flat_time{region},q_new);
end

%% Trying DRAM with the Linear Model
% t_fun = @(q) Linear_Fun(N,flat_time{reg},flat_data{reg},q)
% t_fun(q_new)

[data.xdata,s_index] = sort(flat_time{region});
data.ydata = flat_data{region}(s_index);

SSq_0 = nansum((model_vals - flat_data{region}).^2);
s_0   =  ((1/(length(flat_time{region})-(N+1))) * SSq_0 ).^0.5;
model.ssfun = @(q,data) lin_lsq(N,data.xdata,data.ydata,q);
model.sigma2 = s_0^2;

% Parameters to be used by DRAM
q_0 = q_new;

% Setting the options
options.nsimu = 5000; 
options.updatesigma = 1; 
% options.qcov = V_0;

num_DRAMS = 4;
for i = 1:num_DRAMS
    if i ~= 1
       q_0 = res.mean; 
    end
    
    % Parameter cell array
    for i2 = 0:N
        if i2 == 0
            params = { {"p"+string(i2),q_0(i2+1) } };
        else 
            params = [params,{ {"p"+string(i2),q_0(i2+1) } }];
        end 
    end 

    [res,chain,s2chain] = mcmcrun(model,data,params,options);
end

% Plotting DRAM figures
figure(1); clf; 
mcmcplot(chain,[],res,'chainpanel'); 

figure(2); clf;
mcmcplot(chain,[],res,'pairs');

figure(3); clf;
mcmcplot(chain,[],res,'dens-hist');

%% Using the parameters found in DRAM to plot the actual points and model
q_DRAM = res.mean;
% q_DRAM = chain(end,:);
if fun_type == "sin"
    vals_DRAM = sin_fun(N,t_mesh,q_DRAM);
else 
    vals_DRAM = lin_fun(N,t_mesh,q_DRAM);
end

figure(6); clf
plot(t_mesh,vals_DRAM)
hold on
plot(flat_time{region},flat_data{region},'.')
hold off

%% Using Prediction capabilities of the DRAM codes
% modelfun = @(x,theta) lin_fun(N,x,theta);
% pred_x = t_mesh;
% out = mcmcpred(res, chain, s2chain, data.xdata, modelfun); 
% figure(4); clf;
% mcmcpredplot(out);
% hold on
% plot(data.xdata,data.ydata,'sr'); % add data points to the plot

%%
% t_mesh = linspace(1,num_hours,100);
% N = 3;
% % q_guess = rand(1,N+1);
% q_guess = 2*rand(2,N+1) + -1;
% % 
% q_new = fminsearch( @(q)lin_lsq(N,flat_time{1},flat_data{1},q), q_guess);
% model_mesh_vals = sin_fun(N,t_mesh,q_new);
% figure(1)
% plot(t_mesh,model_mesh_vals)
% hold on
% plot(flat_time{1},flat_data{1},'.')
% hold off

% NOTES:
%   for N = 3 -> q = [0.615530548571756,-0.0450119413794037,0.00537547180319710,-0.000142979280213835]


function fitness = lin_lsq(N,x_vals,y_vals,q)
    fitness = nansum( (y_vals - lin_fun(N,x_vals,q)).^2 );
end

function fitness = sin_lsq(N,x_vals,y_vals,q)
    fitness = nansum( (y_vals - sin_fun(N,x_vals,q)).^2 );
end 

function f = lin_fun(N,x,q)
    for i = 0:N
        if i == 0
            f = q(i + 1) .* x.^i;
        else
            f = f + q(i + 1) .* x.^i;
        end
    end
end
function f = sin_fun(N,x,q)
    for i = 0:N
        if i == 0
            f = q(2,i + 1) ;
        else
            f = f + q(1,i + 1) .* sin(q(2,i+1).*x);
        end
    end
end

















