function [T, x, y, theta] = GetBeidouSensorData(fname)
    %% Open File and Read Data
    
    filename = ['C:\Users\Charles\Documents\RFbeam\MR3003\Position Data\out_' fname '.txt'];
    fileID = fopen(filename); % Open the file
    C = textscan(fileID,'%f %s %f %f %f %*f %f %f %f %f %*[^\n]', 'Delimiter',{'.',',','(',')'},'headerlines', 3);
    fclose(fileID); % Close the file

    %% Extract the Relevant Elements from the Data 

    ind = find(~strcmp(C{1,2},'radar')); % Find all the lines not corresponding to radar
     %ind = find(~strcmp(C{1,2},'husky'));
    A = cell2mat([C(1,3:9) C{1,1}]); % Convert the cell to matrix
    A(ind,:) = [];  % Remove all the lines not corresponding to the radar data

    %% Compute the time of each sample

    dt(:,1:6) = datevec(datetime(A(:,end),'ConvertFrom', 'posixtime')); % Convert time from UNIX to vector
    dt(:,4) = dt(:,4)+8; % Convert hour from UTC to local time
    T = 3600*dt(:,4) + 60*dt(:,5) + dt(:,6); % Convert the time to seconds
    
    x = A(:,1); % Extract the information relative to the X axis
    y = A(:,3); % Extract the information relative to the Y axis
    
    q = A(:,4:7); % Extract the quaternions information
    theta = asind(2*(q(:,1).*q(:,3) - q(:,4).*q(:,2))); % yaw angle
    a22 = q(:,1).^2 - q(:,2).^2 + q(:,3).^2 - q(:,4).^2;
    a23 = 2*(q(:,1).*q(:,3) - q(:,4).*q(:,2));
    a33 = q(:,1).^2 - q(:,2).^2 - q(:,3).^2 + q(:,4).^2;
    theta((a22>=0)|(a33>=0)) = asind(a23((a22>=0)|(a33>=0))); % Correct the yaw angle information
    theta((a22<0)&(a33<0)&(a23>=0)) = 180 - asind(a23((a22<0)&(a33<0)&(a23>=0))); % Correct the yaw angle information
    theta((a22<0)&(a33<0)&(a23<0)) = -180 - asind(a23((a22<0)&(a33<0)&(a23<0))); % Correct the yaw angle information
end