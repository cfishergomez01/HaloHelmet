clear; clc; close all;

% List of .mat files to process
file_list = { ...
    'bk_frimp_lvl1.mat', 'bk_frimp_lvl2.mat', 'bk_frimp_lvl3.mat', ...
    'ch_frimp_lvl1.mat', 'ch_frimp_lvl2.mat', 'ch_frimp_lvl3.mat', ...
    'hp_frimp_lvl1.mat', 'hp_frimp_lvl2.mat', 'hp_frimp_lvl3.mat' ...
};

for i = 1:length(file_list)
    file_name = file_list{i};
    
    % Load the file and check contents
    data = load(file_name);
    vars = fieldnames(data); % Get variable names
    
    if any(strcmp(vars, 'mean_accel')) % Check if 'mean_accel' exists
        mean_accel = data.mean_accel; % Extract mean_accel
        
        % Generate time vector with the same length as mean_accel
        num_points = length(mean_accel);
        time = linspace(0, 0.12, num_points)'; 
        
        % Save back into the file
        save(file_name, 'time', 'mean_accel');
        fprintf('Updated: %s\n', file_name);
    else
        fprintf('Skipping %s (mean_accel not found)\n', file_name);
    end
end

disp('All files processed.');
