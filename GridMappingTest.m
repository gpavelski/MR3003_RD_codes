%% Program Init

clc; clear all; close all;

%% Import Data

filename = 'Record_2019-03-22_12-56-37 - TestB7';
w = strsplit(filename, ' - ');
fname = w{1};
posname = w{2};

fid = fopen(['C:\Users\Charles\Documents\RFbeam\MR3003\' fname ' - ' posname '\' fname '.bin'],'rb');
% open the file on Matlab
D=fread(fid);  %Extract the information contained in this file
fclose(fid); % close the file

C =  D(3:2:end,1) + 256*D(2:2:end,1); % Convert from int8 to int16
RadarM = de2bi(C(17,1)/256);    %Show which modules are on
Rconfig = C(20,1); % Current Range and Speed settings for the radar
Set = [0, 5, 25; 1, 10, 25; 2, 20, 25; 3, 50, 25; 4, 100, 25; 5, 200, 25; ...
    6,10,50; 7,20,50; 8,30,50; 9,100,50; 10,200,50; 11,50,100; 12,100,100; ...
    13,200,100; 14,200,185]; % Matrix of possible configurations of Range/Speed
RangeMax = Set(Rconfig+1,2); % Extract the maximum range
SpeedMax = Set(Rconfig+1,3); % Extract the maximum speed

%% Diagram Initialization

 global h ;
 if RadarM(4) == 1 % It means PDAT is enabled
    mnp = 128;  % Maximum number of points
    m = 20548;
 elseif RadarM(6) == 1  % It means TDAT is enabled
    mnp = 32;  % Maximum number of points
    m = 21572;
 end
 
h = cell(1,mnp); % Initialize the scatter handle array

%% Matrices Declaration

k = find(C(:,1) == m); % Find the indexes relative to the start of each frame
df = diff(k); % Compute the differential of the vector to know the size of each frame
M = zeros(max(df),length(df));  %Initialize the matrix M containing all the frames
r_t = zeros(mnp,length(df)); %Initialize the vector range

theta_t = r_t; % Initialize the vector angle

firstFrame = C(k(1)+df(1)-1);

%% Paste the angle information here

delta_theta = zeros(1,length(df)); % This vector stores the variation in the angle for each frame
%dir = 0; % Initial radar direction
[x,y,theta] = GetPosition(fname,posname,firstFrame);
 %load('thetaBeidou02IMU.mat');
dir = theta(1:length(df))+40;

%% Data Extraction

for i = 1:length(df)    % For each frame...
   M(1:df(i),i) = C(k(i):k(i)+df(i)-1,1);   % Extract the frame i from C to the column i of M
   [r_t(:,i), theta_t(:,i)] = PointPosition(M(:,i)); %Obtain range and angle information
   %dir = dir + delta_theta(i); % Compute the current radar direction
   theta_t(:,i) = theta_t(:,i) - dir(i,1);  % Update the angle of all points of the diagram
end

%% Defining the Grid

Area = (100*RangeMax)^2;   % Area of the map
movPrice = 100*RangeMax; % Price to move
cell_wid = 25%12.5;%6.25; % Cell width in centimeters
ncells = Area/(cell_wid^2); % Compute the number of cells
H = zeros(sqrt(ncells),sqrt(ncells)); % Create the global grid mapping matrix;
xlim = [-100*RangeMax/2 100*RangeMax/2]; %The initial limits for the x axis (min, max)
ylim = [0 100*RangeMax]; %The initial limits for the y axis (min, max)
rpx = 0; % Initial Radar x-position
rpy = 0; % Initial Radar y-position

r_t(r_t < 2*cell_wid) = NaN; % Remove the points too close to the radar

pX = -r_t.*sind(theta_t); % Compute the rotated x-coordinate of all points
pY = r_t.*cosd(theta_t); % Compute the rotated x-coordinate of all points

%% Paste the Position Data Here

pk = zeros(size(pX,2),2);
pk(:,1) = -100*x(1:size(pX,2));
pk(:,2) = 100*y(1:size(pX,2));
pk = cell_wid*round(pk./cell_wid);

%% Computing the grid mapping

for k = 3500:4000%1:size(pX,2)
    Flim = [cell_wid*round(min(pX(:,k))/cell_wid) cell_wid*ceil(max(pX(:,k))/cell_wid); cell_wid*round(min(pY(:,k))/cell_wid) cell_wid*ceil(max(pY(:,k))/cell_wid)];
    % Flim define the limits for both axis in the matrix F
    if Flim(1,1) > 0
        Flim(1,1)= 0;
    end
    if Flim(2,1) > 0
        Flim(2,1) = 0;
    end
    ncellsx = length(Flim(1,1):cell_wid:Flim(1,2))-1;
    ncellsy = length(Flim(2,1):cell_wid:Flim(2,2))-1;
    
    F = zeros(ncellsy,ncellsx); % Create the global grid mapping matrix;
    
    % Generate the current F matrix
    for j = 1:ncellsx % Column
       a = Flim(1,1) + (j-1)*cell_wid;
       b = Flim(1,1) + j*cell_wid;
       for i = 1:ncellsy % Row
          c = Flim(2,2) - i*cell_wid;
          d = Flim(2,2) - (i-1)*cell_wid;
          F(i+(j-1)*ncellsy) = F(i+(j-1)*ncellsy) + length(find((pX(:,k) >= a) & (pX(:,k) <= b) & (pY(:,k) >= c) & (pY(:,k) <= d))); 
       end
    end
    rpx = 0 + pk(k,1); % Radar x-position in the map
    rpy = 0 + pk(k,2); % Radar y-position in the map
    
    Flim(1,:) = Flim(1,:) + rpx; % Based on the radar position, update the limits for F
    Flim(2,:) = Flim(2,:) + rpy;
    
    if xlim(2) - Flim(1,2) < 0 %Check if more columns are necessary to the right
       ncadd = round(abs((xlim(2) - Flim(1,2))/cell_wid));  % Compute the number of columns necessary to add
       xlim(2) = Flim(1,2); % Update the current limits of H
       H(:,end+ncadd) = 0; % Add more columns if necessary
    end
    if xlim(1) - Flim(1,1) > 0 %Check if more columns are necessary to the left
       ncadd = round(abs((xlim(1) - Flim(1,1))/cell_wid));  % Compute the number of columns necessary to add
       xlim(1) = Flim(1,1); % Update the current limits of H
       H(:,end+ncadd) = 0; % Add more columns if necessary
       H = circshift(H,[0 ncadd]); %Shift the zeros to the left
    end
    
    if ylim(2) - Flim(2,2) < 0 %Check if more lines are necessary to the top
       nladd = round(abs((ylim(2) - Flim(2,2))/cell_wid));  % Compute the number of columns necessary to add
       ylim(2) = Flim(2,2); % Update the current limits of H
       H(end+nladd,:) = 0; % Add more lines if necessary
       H = circshift(H,[nladd 0]); % Shift the zeros up
    end
    if ylim(1) - Flim(2,1) > 0 %Check if more lines are necessary to the bottom
       nladd = round(abs((ylim(1) - Flim(2,1))/cell_wid));  % Compute the number of columns necessary to add
       ylim(1) = Flim(2,1); % Update the current limits of H
       H(end+nladd,:) = 0; % Add more lines if necessary
    end
    indx = find(xlim(1):cell_wid:xlim(2) == Flim(1,1)); % Compute the place where F should be "pasted" in H
    indy = find(ylim(2):-cell_wid:ylim(1) == Flim(2,2));
    
    % The map matrix H is updated:
    H(indy:indy+size(F,1)-1,indx:indx+size(F,2)-1) = H(indy:indy+size(F,1)-1,indx:indx+size(F,2)-1) + F;
end

%% Representing the diagram

figure(1); %Open a new figure window
imagesc(20*log10(H)); % Plot the map
colormap('jet(256)'); % Select the colormap to be used
xticklabels = linspace(xlim(1),xlim(2),5*RangeMax/5); % Define the labels of the x-axis
xticks = linspace(1, size(H, 2), numel(xticklabels)); % Define the intervals of the x-axis
set(gca, 'XTick', xticks, 'XTickLabel', xticklabels); % Update the x labels
yticklabels = linspace(ylim(1),ylim(2),10*RangeMax/5); % Define the labels of the y-axis
yticks = linspace(1, size(H, 1), numel(yticklabels)); % Define the intervals of the y-axis
set(gca, 'YTick', yticks, 'YTickLabel', fliplr(yticklabels)); % Update the y labels
xlabel('Range X [cm]'); % Give the name to the x-axis
ylabel('Range Y [cm]'); % Give the name to the y-axis
title(posname);