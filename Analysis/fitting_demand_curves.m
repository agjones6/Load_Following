%% Fitting demand curves using statistical methods
% 
% The demand curve data comes from eia. It was downloaded using python 

%% Importing the data

% Defining the path to the current directory
my_Path = "/Users/AndyJones/Documents/GitHub/master_proj"; % Mac
% my_Path = "C:\Users\agjones6\Documents\GitHub\master_proj"; % Windows

% Defining the directory where the files contain demand data 
my_Dir = "/Grid_Information/Curve_Fitting_Proj/*.csv";

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
%%
r = 2;
hr_mesh = linspace(0,23,100);

hr = 0:23;
for i = 1:length(norm_data{r})
    td1 = norm_data{r}(:,i)';
    td1(isnan(td1)) = 0;
    t_fit1(i,:) = polyfit(hr,td1,5);
    vals1(i,:) = polyval(t_fit1(i,:),hr_mesh);
end
figure(1)
for i = 1:6
    histogram(t_fit1(:,i),10)
    hold on
end
%%
r = 1;
td2 = flat_data{r};
hr2 = flat_time{r};
td2(isnan(td2)) = 0;
[t_fit2,S] = polyfit(hr2,td2,5);

t_fit3 = [-2.6523e-6, 1.4759e-4, -2.9747e-3, 2.6467e-2, -8.7564e-2, 6.90297e-1];
[vals2,delta] = polyval(t_fit2,hr_mesh,S);
vals3 = polyval(t_fit3,hr_mesh);

figure(1);clf
% plot(hr_mesh,vals1,'Linewidth',1.8)
plot(hr_mesh,vals2,'Linewidth',1.8)
hold on
plot(hr_mesh,vals3,'Linewidth',1.8)
plot(hr_mesh,vals2+[2*delta;-2*delta],'--k')
plot(hr2,td2,'*')

% plot(norm_data{2},'*b')

%% Defining a function to be used to fit 
region = 1;
t_mesh = linspace(1,num_hours,500) - 1;
[t_obs,s_index] = sort(flat_time{region});
val_obs = flat_data{region}(s_index);
N = 5;
lb = 0;
ub = 1;
fun_type = "lin";
options.nsimu = 1000; 
num_DRAMS = 1;

% Guessing initial values for the parameters random [-1,1]
if fun_type == "sin"
    q_guess = (ub-lb).*rand(1,(N*2)+1)+lb;
else
    q_guess = (ub-lb).*rand(1,N+1)+lb;
end

% Defining the Least Squares model and Function Model
if fun_type == "sin"
    curr_model = @(time,q) sin_fun(N,time,q); 
    curr_ss = @(time,real_vals,q) sin_lsq(N,time,real_vals,q);
else
    curr_model = @(time,q) lin_fun(N,time,q); 
    curr_ss = @(time,real_vals,q) lin_lsq(N,time,real_vals,q); 
end

% These are the parameters found from the least squares method
q_new = fminsearch( @(q)curr_ss(t_obs,val_obs,q), q_guess);

% Values from the model evaluated at times from the data
model_vals = curr_model(t_obs,q_new);
mesh_vals = curr_model(t_mesh,q_new); 
    
figure(4); clf
plot(t_mesh, mesh_vals, 'LineWidth',2)
hold on
plot(t_obs,val_obs,'*')
title('Least Squares')
hold off

%% Trying DRAM with the Linear Model
% t_fun = @(q) Linear_Fun(N,flat_time{reg},flat_data{reg},q)
% t_fun(q_new)

data.xdata = t_obs;
data.ydata = val_obs;

SSq_0 = nansum((model_vals - val_obs).^2);
s_0   =  ((1/(length(t_obs)-(N+1))) * SSq_0 ).^0.5;
model.sigma2 = s_0^2;
model.ssfun = @(q,data) curr_ss(data.xdata,data.ydata,q);

% Parameters to be used by DRAM
q_0 = q_new;

% Setting the options
options.updatesigma = 1; 
% options.qcov = V_0;


for i = 1:num_DRAMS
    if i ~= 1
       q_0 = res.mean; 
       q_0 = chain(end,:);
    end
    
    % Parameter cell array
    for i2 = 0:(length(q_guess)-1)
        if i2 == 0
            params = { {"p"+string(i2),q_0(i2+1) } };
        else 
            params = [params,{ {"p"+string(i2),q_0(i2+1) } }];
        end 
    end 

    [res,chain,s2chain] = mcmcrun(model,data,params,options);
end

%% Plotting DRAM figures
figure(1); clf; 
mcmcplot(chain,[],res,'chainpanel'); 

% figure(2); clf;
% mcmcplot(chain,[],res,'pairs');

figure(3); clf;
mcmcplot(chain,[],res,'dens-hist');

%% Using the parameters found in DRAM to plot the actual points and model
q_DRAM = res.mean;
q_DRAM = fliplr(t_fit2);
% q_DRAM = chain(end,:);

mesh_DRAM = curr_model(t_mesh,q_DRAM);
vals_DRAM = curr_model(t_obs,q_DRAM);

SSq_0 = curr_ss(t_obs,val_obs,q_DRAM);
DOF = length(val_obs)-length(q_DRAM);
DOF = 24-length(q_DRAM);
s_0   =  ( (1/DOF) * SSq_0 ).^0.5;

%
h = 0.0001;
num_param = length(q_DRAM);
X_0 = zeros(length(t_obs),num_param);
for i = 1:num_param
    base_mat = ones(1,num_param);
    base_mat(i) = base_mat(i) + h;
    val_div = h * q_DRAM(i);
    diff_vals = curr_model(t_obs,q_DRAM.*base_mat);
    
    % Setting up the Sensitivity Matrix
    X_0(:,i) = (  diff_vals - vals_DRAM)./val_div;
end
X_0(isnan(X_0)) = 0;

% Calculating the sensitivity Matrix
V_0 = s_0 * (transpose(X_0)*X_0)^-1;
% V_0 =  (res.S20.^0.5).*(transpose(X_0)*X_0)^-1;
% V_0 = (transpose(X_0)*X_0)^-1;
% V_0 = (res.S20.^2).*res.cov;
% R_0 = chol(V_0);
% V_0 = res.qcov./res.adascale.^2;
SD_q = get_diag(V_0);


% Getting the interval around a function
fun_var = zeros(length(t_obs),1);
for i = 1:length(t_obs)
    S = X_0(i,:)';
    fun_var(i) = transpose(S) * V_0 * S;
end
% Standard Deviation
fun_SD = (fun_var).^0.5;
fun_SD2 = fun_SD;
fun_SD2 = flatten_mat(t_obs,fun_SD2);

% Getting the max Standard deviation for each time value
curr_max = 0;


% Trying to get confidence intervals
conf_interval = 0.90;
t_val = tinv(conf_interval, DOF);


%
figure(6); clf
plot(t_mesh,mesh_DRAM,'LineWidth',2)
hold on
plot(t_obs,val_obs,'*')
plot(t_obs,vals_DRAM+t_val.*[fun_SD2,-fun_SD2],'-k','Linewidth',2)
% plot(t_obs,test_UB,'-k','Linewidth',2)
title('DRAM Final')
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
function f = flatten_mat(t_obs,X)
    for i = 1:length(t_obs)-1
        if i == 1
            st = i;
        elseif t_obs(i) ~= t_obs(i+1)
            en = i;
            X(st:en) = mean(X(st:en));
            st = i + 1;
        elseif i == length(t_obs) - 1
            X(st:end) = mean(X(st:end));
        end    
    end
    f = X;
end 
function new_mat = get_diag(X)
    new_mat = ones(1,length(X));
    for i = 1:length(X)
       new_mat(i) = X(i,i);
    end
end
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
    num_el = N * 2 + 1;
    i = 1;
    c = 0;
    while i < num_el 
        if i == 1
            f = q(i) ;
            i = i + 1;
        else
            if c == 0
                f = f + q(i) .* sin(q(i+1).*x);
                i = i + 2;
                c = 1;
            else
                f = f + q(i) .* sin(q(i+1).*x);
                i = i + 2;
                c = 0;
            end
        end
    end
end

















