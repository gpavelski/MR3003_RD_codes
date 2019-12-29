%% Program init

clear all; close all; clc; 


%% Opening the saved file
fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_2019-04-02_09-43-58 - RDDA\Record_2019-04-02_09-43-58.bin','rb');
% open the file on Matlab
C=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file
 
M = floor(length(C)/(128*128)); % Based on the data available in datasheet, compute the number of frames
R = zeros(128,M); % Initialize the matrix M

%% Graphical Representation

 for j = 1:M
    R(:,j) = C((128*j-1)*128+1:128*j*128); % Transform the single column vector in a matrix with M columns
    figure(1); % Open a new figure window
    hold on;  % Hold the plot;
    %axis([0 256 -6000 6000]); % Define the axis
    if rem(j,4) == 1
        if j > 4
            delete(p1);
        end
        p1 = plot(R(:,j),'b');
    elseif rem(j,4) == 2
        if j > 4
            delete(p2);
        end
        p2 = plot(R(:,j),'g');
    elseif rem(j,4) == 3
        if j > 4
            delete(p3);
        end
        p3 = plot(R(:,j),'m');
    elseif rem(j,4) == 0
        if j > 4
            delete(p4);
        end
        p4 = plot(R(:,j),'r');
    end
    pause(0.05);
 end
 legend('RX1','RX2','RX3','RX4');
 grid on;
