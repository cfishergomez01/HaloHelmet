close all; clear; clc;

% Heights of APs (cm)
h_ch = 41; % Chest
h_bk = 9;  % Back
h_hp = 7;  % Hip

% Heights of impacts (cm)
imp_fr = 43; % Front impact
imp_sd = 66; % Side impact

% Folders
folders = {'Front', 'Side'};

% Loop through each folder
for f = 1:length(folders)
    folder_name = folders{f};
    files = dir(fullfile(folder_name, '*.mat')); % Get .mat files
    
    % Determine which impact height to use
    if strcmp(folder_name, 'Front')
        h_imp = imp_fr;
    else
        h_imp = imp_sd;
    end

    % Process each file
    for i = 1:length(files)
        file_path = fullfile(folder_name, files(i).name);
        data = load(file_path);

        % Extract AP height based on filename
        if contains(files(i).name, 'ch')
            h_anchor = h_ch;
        elseif contains(files(i).name, 'bk')
            h_anchor = h_bk;
        elseif contains(files(i).name, 'hp')
            h_anchor = h_hp;
        else
            warning('Unknown AP in %s, skipping...', files(i).name);
            continue;
        end

        % Apply compensation formula
        accel_adjusted = (h_imp / h_anchor) * data.mean_accel;

        % Save adjusted acceleration back to the struct
        data.accel_adjusted = accel_adjusted;
        save(file_path, '-struct', 'data');

        % Plot original and adjusted acceleration in a separate figure
        figure;
        hold on;
        title(['Acceleration Comparison - ' files(i).name], 'Interpreter', 'none');
        xlabel('Time Index');
        ylabel('Acceleration (G)');
        plot(data.mean_accel, '--', 'DisplayName', 'Original'); % Dashed line for original
        plot(accel_adjusted, '-', 'DisplayName', 'Adjusted');    % Solid line for adjusted
        legend;
        hold off;

        fprintf('Processed %s: AP Height = %d cm, Impact Height = %d cm\n', ...
            files(i).name, h_anchor, h_imp);
    end
end

disp('Processing and plotting complete.');
