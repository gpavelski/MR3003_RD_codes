function [T, theta,ax,ay,az] = GetPosition(fname,posname,start)
    
    filename = ['C:\Users\Charles\Documents\RFbeam\MR3003\' fname ' - ' posname '\' fname '.csv']; % Define the address of the file to open
    fileID = fopen(filename); % Open the file
    C = textscan(fileID,'"%*d %f %f %f %*[^\n]', 'Delimiter', {'","',':'}, 'headerlines', 1);
    fclose(fileID); % Close the file
    [Tb,theta,ax,ay,az] = GetIMUSensorData(fname,posname);
    %% Extract the Time Information

    T = C{1,1}*3600 + C{1,2}*60 + C{1,3}; % Convert the time to seconds
    while start-1 > length(T)
        peaks = find(abs(diff(T)) > 0.1); % Find the index of the peaks in the first derivative of the time
        start = max(peaks); % Find the maximum value (last)
        peaks(end) = []; % 
    end
    T(1:start-1) = [];

    %% Find the closest match to each time value


    A = repmat(Tb,[1 length(T)]);
    [minValue,closestIndex] = min(abs(A-T'));
% 
%      x = x(closestIndex);
%      y = y(closestIndex);
    theta = theta(closestIndex);
%     x = zeros(length(theta),1);
%     y = zeros(length(theta),1);
    ax = smooth(ax(closestIndex,1),0.02,'sgolay',2);
    ay = smooth(ay(closestIndex,1),0.02,'sgolay',2);
    az = smooth(az(closestIndex,1),0.02,'sgolay',2);

end