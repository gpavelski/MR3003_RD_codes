function [Tv,yaw,ax,ay,az] = GetIMUSensorData(fname,posname)

    %% Open File and Read Data

    filename = ['C:\Users\Charles\Documents\RFbeam\MR3003\' fname ' - ' posname '\' posname 'IMU.txt']; 
    fileID = fopen(filename); % Open the file
    C = textscan(fileID,'%f %f %f -> %f %f %f %f %f %f', 'Delimiter',{':','\t',',',' '});
    fclose(fileID); % Close the file
    
    Tv = 3600.*C{1,1} + 60.*C{1,2} + C{1,3};
    Data = cell2mat(C(1,4:9)); % Convert the data to matrix format
    
    ax = 9.81*Data(:,1);
    ay = 9.81*Data(:,2);
    az = 9.81*Data(:,3);
    yaw = Data(:,6);
 end
    
