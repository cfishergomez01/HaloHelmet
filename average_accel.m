clear; clc; close all;

%% Inputs to change 
save_file_name = 'bk_frimp_lvl2.mat';
files = {'bkf2_1_truncated.mat', 'bkf2_2_truncated.mat', 'bkf2_3_truncated.mat', 'bkf2_4_truncated.mat'};

%% Time shifting and mean computation

% List of impact data files
num_files = length(files);
data_struct = struct();

min_length = inf; % Track the shortest dataset length
peak_idx_all = zeros(1, num_files); % Store peak indices for alignment
peak_time_all = zeros(1, num_files); % Store the time of the peak for each dataset

% Load and process each file
for i = 1:num_files
    % Check if file exists
    if ~isfile(files{i})
        warning(['File not found: ' files{i}]);
        continue; % Skip this file
    end
    
    load(files{i}, 'time_truncated', 'accel_truncated'); % Load variables

    % Ensure the variables exist in the loaded file
    if ~exist('time_truncated', 'var') || ~exist('accel_truncated', 'var')
        warning(['Missing expected variables in: ' files{i}]);
        continue; % Skip if variables are missing
    end
    
    % Find indices where acceleration exceeds 1g
    g_threshold = 1; % 1g is 1 in this case
    start_idx = find(abs(accel_truncated) > g_threshold, 1);

    if isempty(start_idx)
        warning(['No acceleration exceeding 1g in file: ' files{i}]);
        continue;
    end

    % Trim data from impact start onwards
    time = time_truncated(start_idx:end);
    accel = accel_truncated(start_idx:end);

    % Find peak acceleration index
    [~, peak_idx] = max(abs(accel));

    % Store the peak index and peak time for later alignment
    peak_idx_all(i) = peak_idx;
    peak_time_all(i) = time(peak_idx); % Store the peak time for each dataset

    % Store processed data
    data_struct(i).time = time(:);  % Ensure column vector
    data_struct(i).accel = accel(:); % Ensure column vector
    
    % Update min length
    min_length = min(min_length, length(accel));
end

% Align datasets based on the peak time (make peaks occur at time = 0)
reference_peak_time = peak_time_all(1); % Use the peak time from the first dataset

for i = 1:num_files
    % Recenter each dataset around its own peak (time = 0 at the peak)
    time_shift = peak_time_all(i); % Get the peak time for the current dataset
    data_struct(i).time = data_struct(i).time - time_shift; % Center time around peak
    
    % Replace time values with the common time reference (based on first dataset)
    data_struct(i).time = data_struct(i).time + reference_peak_time;
    
    % Trim all datasets to match the shortest length
    data_struct(i).time = data_struct(i).time(1:min_length);
    data_struct(i).accel = data_struct(i).accel(1:min_length);
end

% Resample the acceleration data to match the common time vector
time_common = data_struct(1).time;

for i = 1:num_files
    % Use 'linear' interpolation, but also ensure no extrapolation at edges
    data_struct(i).accel = interp1(data_struct(i).time, data_struct(i).accel, time_common, 'linear');
    
    % Remove NaN values after resampling (if any)
    data_struct(i).accel(isnan(data_struct(i).accel)) = 0;
end

% Compute the mean acceleration after resampling
mean_accel = mean(cell2mat(arrayfun(@(x) x.accel, data_struct, 'UniformOutput', false)), 2);

% Save the mean acceleration data to the specified .mat file
save(save_file_name, 'mean_accel');

% Plot raw data (each dataset in its own figure)
for i = 1:num_files
    figure;
    plot(time_common, data_struct(i).accel, 'DisplayName', ['Impact ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Acceleration (g)');
    title(['Raw Data for Impact ' num2str(i)]);
    grid on;
    legend;
end

% Plot results for the mean data
figure;
hold on;

% Plot individual raw data
for i = 1:num_files
    plot(time_common, data_struct(i).accel, 'DisplayName', ['Impact ' num2str(i)]);
end

% Plot the mean impact data
plot(time_common, mean_accel, 'k', 'LineWidth', 2, 'DisplayName', 'Mean Impact');
xlabel('Time (s)');
ylabel('Acceleration (g)');
legend;
grid on;
title('Impact Acceleration Data');
