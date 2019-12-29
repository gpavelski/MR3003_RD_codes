%% Program Init

clc; clear all; close all;

%% Import Data

fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_2018-11-16_11-04-23 - Lab\Record_2018-11-16_11-04-23.bin','rb');
% open the file on Matlab
D=fread(fid);  %Extract the information contained in this file
fclose(fid); % close the file

C =  D(3:2:end,1) + 256*D(2:2:end,1) ;
RadarM = de2bi(C(17,1)/256);    %Show which modules are on
Rconfig = C(20,1); % Current Range and Speed settings for the radar
Set = [0, 5, 25; 1, 10, 25; 2, 20, 25; 3, 50, 25; 4, 100, 25; 5, 200, 25; ...
    6,10,50; 7,20,50; 8,30,50; 9,100,50; 10,200,50; 11,50,100; 12,100,100; ...
    13,200,100; 14,200,185]; % Matrix of possible configurations of Range/Speed
RangeMax = Set(Rconfig+1,2);
SpeedMax = Set(Rconfig+1,3);

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

figure(1);
for i = 1:mnp
    h{i} = scatter(NaN, NaN, 'filled'); %// empty plot
    hold on
end
title('Range-Range Diagram');
xlabel('Range X [cm]');
ylabel('Range Y [cm]');
grid on;
axis manual %// this line freezes the axes
axis([-50*RangeMax 50*RangeMax 0 100*RangeMax]);    % Update the axis of the figure considering the radar cfg

%% Radar Parameters Extraction

% TXSet = [0,-45;1,-25; 2,-15; 4,-10; 7,-5; 11,0; 20,5; 37,10; 63,15];
% Mode = C(20,1); % 0 for FMCW, 1 for CW
% frau = de2bi(C(22,1)); % Auxiliary variable for computing the frequency
% frind = bi2de(frau(9:end)); %Frequency index
% Freq = (frind-40)*250 + 76000; %Carrier Frequency (MHz)
% RXGain = de2bi(C(23,1)); % Fake Gain
% RXGain = bi2de(RXGain(9:end)); % Real Receiver Gain
% AuxV = de2bi(C(24,1)); %Auxiliary Variable to Compute Tranmitter settings
% TxNum = bi2de(AuxV(1:2)) + 1; % Transmitter Antenna Number
% TXGainInd = find(TXSet(:,1) == bi2de(AuxV(9:end)));    %Compute the Transmitter Gain index
% TXGain = TXSet(TXGainInd,2); %Transmitter Gain [dBm]
% DPbin(1:2,:) = de2bi(C(25:26,1)); % Extract the Information about the Detection Parameters
% if size(DPbin,2) > 8
%     RND = bi2de(DPbin(1,1:6)); % Range Neighbour Delta [bin] from 0 to 63
%     SND = bi2de(DPbin(1,9:end)); % Range Neighbour Delta [bin] from 0 to 63
%     MRB = bi2de(DPbin(2,1:8)); % Minimum Range [bin] from 0 to 63
%     RadPos = bi2de(DPbin(2,9:end)); % Radar position: 0 = static, 1 = moving
% else
%     RND = bi2de(DPbin(1,1:end)); % Range Neighbour Delta [bin] from 0 to 63
%     SND = 0; % Range Neighbour Delta [bin] from 0 to 63
%     MRB = bi2de(DPbin(2,1:end)); % Minimum Range [bin] from 0 to 63
%     RadPos = 0; % Radar position: 0 = static, 1 = moving
% end
% StObin = de2bi(C(27,1)); % Convert to binary the value of line 27
% StObj = bi2de(StObin(1)); % Static Objects: 0 = Off, 1 = On.
% rest = StObin(9:end); % Part of this number corresponds to the MOS
% MOSbin = de2bi(C(28,1));    % Convert the number to binary
% if length(MOSbin) > 7
%     MOS = bi2de([MOSbin(1:8) rest])/100; % Maximum own speed [km/h] 
% else
%     MOS = bi2de([MOSbin(1:end) rest])/100; % Maximum own speed [km/h] 
% end
% Ctimeb(1:2,:) = de2bi(C(29:30,1));
% Ctime = bi2de([Ctimeb(1,1:8) MOSbin(9:end)])/100; % Collision time [s]
% CBF = bi2de([Ctimeb(2,1:8) Ctimeb(1,9:end)])/100; % Clutter Band Factor
% MiLT = bi2de(Ctimeb(2,9:end)); % Tracking Minimum Life Time [frame]
% MaLTi = de2bi(C(31,1));
% MaLT = bi2de(MaLTi(1:8)); % Tracking Maximum Life Time [frame]

%% Matrices Declaration

k = find(C(:,1) == m); % Find the indexes relative to the start of each frame
df = diff(k);
M = zeros(max(df),length(df));  %Initialize the matrix M containing all the frames

%% Data Extraction

for i = 1:length(df)    % For each frame...
   M(1:df(i),i) = C(k(i):k(i)+df(i)-1,1);   % Extract the frame i from C to the column i of M
   Update_Diagram(M(:,i),M(4,i)/10);
end