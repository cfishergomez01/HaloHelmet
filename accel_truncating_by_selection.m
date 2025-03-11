close all; clear; clc;

% Load the .mat file

%*** change to desired file name/path
filename = 'G:\.shortcut-targets-by-id\13s-wBtfaMfkOwHortjul4ECnBtBYW6k_\2025Wi-09\Accel. Data\Sideimpact\HIPS\HIPR\hiplvl3\hp3_2.mat';
data = load(filename);

% Extract variables

%*** change to desired vertical axis variable
if isfield(data, 'accelMagnitude')

    %*** change to desired vertical axis variable
    y = data.accelMagnitude;
else
    error('Variable "y" not found in hp_1.1.mat');
end

% Check if 'x' exists, otherwise use indices

%*** change to desired horitzontal axis variable
if isfield(data, 'timeVector')

    %*** change to desired horizonal axis variable
    x = data.timeVector;
else
    x = (1:length(y))'; % Default to indices if 'x' is missing
end

% Plot the data
figure;
plot(x, y, 'b', 'LineWidth', 1.5);
xlabel('X-axis');
ylabel('Y-axis');
title('Select Start and End Points');
grid on;
hold on;

% Get user input for two points
disp('Click two points to select the truncation range.');
[x_selected, ~] = ginput(2);
x_selected = sort(x_selected); % Ensure start is before end

% Find the closest indices
[~, idx_start] = min(abs(x - x_selected(1)));
[~, idx_end] = min(abs(x - x_selected(2)));

% Truncate the data
time_truncated = x(idx_start:idx_end);
accel_truncated = y(idx_start:idx_end);

% Plot the selected range
plot(time_truncated, accel_truncated, 'r', 'LineWidth', 2);
legend('Original Data', 'Truncated Data');
hold off;

% Generate new filename
new_filename = strrep(filename, '.mat', '_truncated.mat');

% Save truncated data
save(new_filename, 'time_truncated', 'accel_truncated');

disp(['Data truncated and saved as ', new_filename]);