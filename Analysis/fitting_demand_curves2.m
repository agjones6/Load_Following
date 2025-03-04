%% Fitting demand curves using statistical methods
% 
% The demand curve data comes from eia. It was downloaded using python 

%% Importing the data

% Defining the path to the current directory
my_Path = "/Users/AndyJones/Documents/GitHub/master_proj"; % Mac
% my_Path = "C:\Users\agjones6\Documents\GitHub\master_proj"; % Windows

% Defining the directory where the files contain demand data 
my_Dir = "/Grid_Information/Curve_Fitting/*.csv";

% Getting all of the csv files in the folder location with 
my_Files = dir(my_Path + my_Dir);

% Establishing the 

% Getting the names of the csv files
csv_names = strings(1,length(my_Files));
case_names = cell(1,length(my_Files));
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
    
    dum_c = strsplit(my_Files(i).name,".");
    case_names{i} = dum_c{1};
end


% figure(1)
% plot(norm_data{1},'*r')
% hold on
% plot(norm_data{2},'*b')

%% Defining a function to be used to fit 
region = 2;
N = 5;
fun_type = "lin";
num_iter = 5000;
num_DRAMS = 4;
conf_interval = 0.95;

% Guessing initial values for the parameters random [-1,1]
lb = 0;
ub = 1;
if fun_type == "sin" 
    if N == 4
        q_guess = [0.660140372731553,-0.0326841283891038,-21561805.4814931,-0.0671307402066448,0.294232559170323,-0.0664517993674296,-31.4853856934355,-0.0260949137902244,0.548562470514929];
    else
        q_guess = (ub-lb).*rand(1,(N*2)+1)+lb;
    end
else
    % This takes care of known cases to lessen the computation needed. 
    if N == 5
        q_guess = [0.6,-0.06,0.017,-0.0016,6.8e-05,-1.0e-06] ;
    else
        q_guess = (ub-lb).*rand(1,N+1)+lb;
    end 
end


% Defining the Least Squares model and Function Model
if fun_type == "sin"
    curr_model = @(time,q) sin_fun(N,time,q); 
    curr_ss = @(time,real_vals,q) sin_lsq(N,time,real_vals,q);
else
    curr_model = @(time,q) lin_fun(N,time,q); 
    curr_ss = @(time,real_vals,q) lin_lsq(N,time,real_vals,q); 
end

% Defining an array of 24 hrs 
hrs = (1:24) - 1;

% Preallocation
t_obs_mat = cell(length(flat_data),1);
y_obs_mat = cell(length(flat_data),1);
q_vals = cell(length(flat_data),1);
SD_vals = cell(length(flat_data),1);
cov_mat = cell(length(flat_data),1);
results = cell(length(flat_data),1);
f_chain = cell(length(flat_data),1);
DOF = cell(length(flat_data),1);
t_val = cell(length(flat_data),1);
model_vals = cell(length(flat_data),1);
model_UB = cell(length(flat_data),1);
model_LB = cell(length(flat_data),1);
for i = 1:length(case_names)
    if i ~= 1
        q_guess = a ;
        num_iter = 5000;
        num_DRAMs = 4;
    end 
    
    [t_obs,s_index] = sort(flat_time{i});
    val_obs = flat_data{i}(s_index);

    [a, b, c,d,e] = get_info(N,curr_model,curr_ss, q_guess, num_iter, num_DRAMS, conf_interval, t_obs, val_obs);
    
    % Assigning the temporary values to cell arrays 
    t_obs_mat{i} = t_obs;
    y_obs_mat{i} = val_obs;
    q_vals{i}    = a;
    SD_vals{i}   = b;
    cov_mat{i}   = c;
    results{i}   = d;
    f_chain{i}   = e;
    
    % Getting the degrees of freedom of the model
    DOF{i} = length(hrs)-length(q_vals{i});
    
    % This it the t values for the confidence interval 
    t_val{i} = tinv(conf_interval, DOF{i});
    
    % Getting the values from the model, the upper bounds and lower bounds
    model_vals{i} = curr_model(hrs,q_vals{i});
    model_UB{i} = model_vals{i} + SD_vals{i}.*t_val{i};
    model_LB{i} = model_vals{i} - SD_vals{i}.*t_val{i};
end 


%%

for r = 1:length(case_names)
    figure(r); 
    plot(hrs,model_vals{r},'Linewidth',2)
    hold on
    plot(t_obs_mat{r},y_obs_mat{r},'*')
    % plot(t_obs_mat(1,:),vals_model+t_val.*[fun_SD2,-fun_SD2],'-k','Linewidth',2)
    plot(hrs,[model_UB{r};model_LB{r}],'--k','Linewidth',2)
    title(case_names{r},'Interpreter','none')
    legend("model","observations","confidence interval",'Location','best')
    hold off
%     saveas(gcf,strcat(my_Path,"/",  "Grid_Information/Curve_Fitting/Results/Pictures/" + fun_type + string(N)+ "_" + case_names{r}+".png"));
%     close(gcf)
end

%%
r = 5;
figure(7); clf; 
mcmcplot(f_chain{r},[],results{r},'dens-hist'); % 'chainpanel' 'pairs' 'dens-hist'

%%
function [q_DRAM, vals_SD_cond, V_0, res, chain] = get_info(N,curr_model,curr_ss,q_guess,num_iter,num_DRAMS,conf_interval,t_obs,val_obs)
    t_mesh = linspace(1,24,500);
    options.nsimu = num_iter;

    % These are the parameters found from the least squares method
    q_new = q_guess;
%     q_new = fminsearch( @(q)curr_ss(t_obs, val_obs, q), q_guess);

    % Values from the model evaluated at times from the data
    model_vals = curr_model(t_obs,q_new);
    mesh_vals = curr_model(t_mesh,q_new); 

%     figure(4); clf
%     plot(t_mesh, mesh_vals, 'LineWidth',2)
%     hold on
%     plot(t_obs,val_obs,'*')
%     title('Least Squares')
%     hold off

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
%            q_0 = chain(end,:);
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
%     figure(1); clf; 
%     mcmcplot(chain,[],res,'chainpanel'); 

    % figure(2); clf;
    % mcmcplot(chain,[],res,'pairs');

%     figure(3); clf;
%     mcmcplot(chain,[],res,'dens-hist');

    %% Using the parameters found in DRAM to plot the actual points and model
    q_DRAM = res.mean;
    % q_DRAM = chain(end,:);

    mesh_DRAM = curr_model(t_mesh,q_DRAM);
    vals_DRAM = curr_model(t_obs,q_DRAM);

    SSq_0 = curr_ss(t_obs,val_obs,q_DRAM);
    DOF = length(val_obs)-length(q_DRAM);
    DOF = 24-length(q_DRAM);
    s_0   =  ( (1/DOF) * SSq_0 ).^0.5;

    %
    h = 0.001;
    num_param = length(q_DRAM);
    X_0 = zeros(length(t_obs),num_param);
    for i = 1:num_param
        base_mat = ones(1,num_param);
        base_mat(i) = base_mat(i) + h;
        val_div = h * q_DRAM(i);
        diff_vals = curr_model(t_obs,q_DRAM.*base_mat);

        % Setting up the Sensitivity Matrix
        X_0(:,i) = (  diff_vals - val_obs)./val_div;
    end
    X_0(isnan(X_0)) = 0;

    % Calculating the sensitivity Matrix
    V_0 = s_0^2 * (transpose(X_0)*X_0).^-1;
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

    % Trying to get confidence intervals
    t_val = tinv(conf_interval, DOF);

    % Getting the upper bound values
    vals_DRAM_flat = condense_mat(t_obs,vals_DRAM);
    vals_SD_cond = condense_mat(t_obs,fun_SD2);
    
end 


%%
function f = condense_mat(t_obs,X)
    c = 1;
    for i = 1:length(t_obs)-1
        if i == 1
            st = i;
        elseif t_obs(i) ~= t_obs(i+1)
            en = i;
            f(c) = mean(X(st:en));
            st = i + 1;
            c = c + 1;
        elseif i == length(t_obs) - 1
            f(c) = mean(X(st:end));
            c = c + 1;
        end    
    end
    
end 
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

















