% Define serial port settings
port = '/dev/cu.usbmodem166325601'; % Update accordingly
baudRate = 230400;
BUFFER_SIZE = 16000; % Must match Teensy buffer size

% Open Serial Connection
serialObj = serialport(port, baudRate);
configureTerminator(serialObj, "LF"); 
flush(serialObj); % Clear buffer
serialObj.Timeout = 10; % Increase timeout for stability

disp("Type 'S' to start sampling or 'C' to calibrate the sensor.");

% **User input loop for calibration or sampling**
while true
    userInput = input("Enter 'S' to start sampling or 'C' to calibrate: ", 's');
    
    if strcmpi(userInput, 'C')
        writeline(serialObj, 'C'); % Send calibration command
        disp("Calibrating... Keep sensor still.");
        
        % Wait for Teensy's response (Calibration completion)
        while true
            line = readline(serialObj);
            disp(line);
            if contains(line, "Calibration complete")
                disp("Calibration done. You can now start sampling.");
                break;
            end
        end
        
    elseif strcmpi(userInput, 'S')
        writeline(serialObj, 'S'); % Send start command
        
        % **Countdown Display**
        disp("Starting in...");
        for i = 3:-1:1
            fprintf("%d...\n", i);
            pause(1); % Wait 1 second per step
        end
        disp("Sampling started...");
        
        break; % Exit loop and proceed with data collection
        
    else
        disp("Invalid input. Type 'S' to start or 'C' to calibrate.");
    end
end

% **Wait for Teensy to start sending data**
disp("Waiting for data...");
data = zeros(BUFFER_SIZE, 4); % [Index, X, Y, Z]

while true
    line = readline(serialObj);
    if contains(line, "Sampling complete. Data:")
        disp("Receiving data...");
        break; 
    end
end

% **Read Data**
i = 1;
while i <= BUFFER_SIZE
    line = readline(serialObj); % Read a line from serial
    values = sscanf(line, '%f,%f,%f,%f'); % Parse CSV format
    
    if length(values) == 4
        data(i, :) = values'; % Store parsed data
        i = i + 1;
    end
end

% **Read Time Taken**
while true
    line = readline(serialObj);
    if contains(line, "Time taken:")
        timeTakenMs = sscanf(line, 'Time taken: %f ms');
        break;
    end
end

% Close serial connection
clear serialObj;

% **Compute time axis**
totalTimeSeconds = timeTakenMs / 1000; % Convert ms to seconds
timeVector = linspace(0, totalTimeSeconds, BUFFER_SIZE); % Evenly spaced time values

% **Extract acceleration data**
accelX = data(:, 2);
accelY = data(:, 3);
accelZ = data(:, 4);

% **Compute total acceleration magnitude**
accelMagnitude = sqrt(accelX.^2 + accelY.^2 + accelZ.^2);

% **Noise Reduction: Use Median Filter**
windowSize = 50;  % Keep it small to preserve high peaks
accelX_smooth = medfilt1(accelX, windowSize);
accelY_smooth = medfilt1(accelY, windowSize);
accelZ_smooth = medfilt1(accelZ, windowSize);

% **Compute total acceleration magnitude filtered**
accelMagnitude_smooth = sqrt(accelX_smooth.^2 + accelY_smooth.^2 + accelZ_smooth.^2);
%% **Plot Comparison: Raw vs. Smoothed Data + Magnitude Graph**
figure;

% **X-Axis Acceleration**
subplot(5,2,1);
plot(timeVector, accelX, 'b', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('Acceleration X (g)');
title('X-Axis Raw Data');
grid on;

subplot(5,2,2);
plot(timeVector, accelX_smooth, 'b', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration X (g)');
title('X-Axis Smoothed (Median Filter)');
grid on;

% **Y-Axis Acceleration**
subplot(5,2,3);
plot(timeVector, accelY, 'r', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('Acceleration Y (g)');
title('Y-Axis Raw Data');
grid on;

subplot(5,2,4);
plot(timeVector, accelY_smooth, 'r', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration Y (g)');
title('Y-Axis Smoothed (Median Filter)');
grid on;

% **Z-Axis Acceleration**
subplot(5,2,5);
plot(timeVector, accelZ, 'g', 'LineWidth', 1);
xlabel('Time (s)'); ylabel('Acceleration Z (g)');
title('Z-Axis Raw Data');
grid on;

subplot(5,2,6);
plot(timeVector, accelZ_smooth, 'g', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Acceleration Z (g)');
title('Z-Axis Smoothed (Median Filter)');
grid on;

% **Total Acceleration Magnitude**
subplot(5,1,4);
plot(timeVector, accelMagnitude, 'k', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Total Acceleration (g)');
title('Total Acceleration Magnitude (Raw Data)');
grid on;

sgtitle('Accelerometer Data: Raw vs. Smoothed + Magnitude');

% **Total Acceleration Magnitude**
subplot(5,1,5);
plot(timeVector, accelMagnitude_smooth, 'k', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Total Acceleration (g)');
title('Total Acceleration Magnitude (filtered)');
grid on;
