%% Program Init

close all; %clearvars M s;
%clear all;

%% Initializing the Variables
 
Set = [0, 5, 25; 1, 10, 25; 2, 20, 25; 3, 50, 25; 4, 100, 25; 5, 200, 25; ...
    6,10,50; 7,20,50; 8,30,50; 9,100,50; 10,200,50; 11,50,100; 12,100,100; ...
    13,200,100; 14,200,185]; % Matrix of possible configurations of Range/Speed
TXSet = [0,-45;1,-25; 2,-15; 4,-10; 7,-5; 11,0; 20,5; 37,10; 63,15];

 flg = 0;  % Used to stop the loop
 pst = 0;   % Incomplete frame indication
 k = 1; % Loop counter
 np = 500; % Number of packages received
 global h ;
 
r_t = zeros(128,1);  % Range vector
angle_t = r_t;  % Angle vector

h = cell(1,size(r_t,1)); % Initialize the scatter handle array

figure(1);
for i = 1:size(r_t,1)
    h{i} = scatter(NaN, NaN, 'filled','r'); %// empty plot
    hold on
end
title('Range-Range Diagram');
xlabel('Range X [cm]');
ylabel('Range Y [cm]');
grid on;
axis manual %// this line freezes the axes

 RXGain = 44; % Receiver Gain
 TXAN = 2; % Transmitter antenna number
 RSSR = 2; % Range and Speed Settings
 MSG = {'52414443', '52444441', '52415244', '50444154', '444f4e45', '54444154', '5250524d'};
 % Possible active messages: RADC, RDDA, RARD, PDAT, DONE, TDAT and RPRM
 
%% Define the TCP/IP connection

% Create TCP/IP object 't'. Specify server machine and port number. 
t = tcpip('192.168.100.5', 6172); 

% Set size of receiving buffer, if needed. 
set(t, 'InputBufferSize', 1446); 

% Open connection to the server. 
fopen(t); 
% Transmit data to the server (or a request for data from the server). 

 fwrite(t,'INIT'); % Start to push data from the server
 pause(1); % Pause for the communication delay, if needed.
 
 %% Extract current radar configs
 
 RPRM= RPRM_Collect(t); %Obtain current radar settings
 Mact = de2bi(RPRM(17,1));  % Messages Active
 rxG = RPRM(23,1)-54272;    % Extract the current receiver gain information
 TXMode = de2bi(RPRM(24,1));    % Obtain information about transmitter parameters
 TXGainInd = find(TXSet(:,1) == bi2de(TXMode(1:6)));    %Compute the Transmitter Gain index
 TXGain = TXSet(TXGainInd,2);   % Obtain the transmitter gain
 if length(TXMode) < 8  
     TXAnt = 0; % Extract the TX Antenna number
 else
    TXAnt = bi2de(TXMode(9:end));
 end

 %% Update Parameters
 
 if rxG ~= RXGain
    String = char(sscanf(['52535247' '00000004000000' dec2hex(RXGain)],'%2X').'); %RSRG
    fwrite(t,String);   % Update the Radar Gain
 end
 if TXAN ~= TXAnt
    AntennaMsg = char(sscanf(['5458414e' '00000004000000' dec2hex(TXAN)] ,'%2X').'); %TXAN
    fwrite(t,AntennaMsg);
 end
 if RSSR ~= Set(RPRM(21,1)/256 + 1,1)
    RangeMax = Set(RSSR + 1,2);  % Extract the maximum range information
    SpeedMax = Set(RSSR + 1,3);  % Extract the maximum speed information
    RSSRMsg = char(sscanf(['52535352' '00000004000000' dec2hex(RSSR)] ,'%2X').'); %RSSR
    fwrite(t,RSSRMsg);  % Update the Range and Speed Parameters
 else
      RangeMax = Set(RPRM(21,1)/256 + 1,2);  % Extract the maximum range information
      SpeedMax = Set(RPRM(21,1)/256 + 1,3);  % Extract the maximum speed information
 end
 if Mact(5) == 0 % Check if the DONE messages are active
     d = 4; % The DONE message affects the size of each frame message
 else
     d = 10;
 end
  Md = [Mact(1:3) 0 0 Mact(6) 0];
 if sum(Md) > 0 % Verify that only the necessary messages are enabled
     idx = find(Md == 1);   % If not, find which message is currently active
     for i = 1:length(idx)
         RModeD = char(sscanf(['44534630' '00000004' MSG{idx}],'%2X').'); %DSF0 Disable Messages
         fwrite(t,RModeD);
     end
 end
 if Mact(4) == 0    % If PDAT is off, then turn it on
      RModeE = char(sscanf(['44534631' '00000004' MSG{4}],'%2X').'); %DSF1 Enable PDAT
      fwrite(t,RModeE);
 end
 
 figure(1);
 axis([-50*RangeMax 50*RangeMax 0 100*RangeMax]);    % Update the axis of the figure considering the radar cfg

  %% Data Streaming
  
 len = 1446;
 while flg ~= 1
     r = fread(t,len);    % Read the data
     v(1:len/2,1) =  256*r(1:2:end-1,1) + r(2:2:end,1); 
     
         st = find(v == 20548); % Positions relative to start of each frame
         lst = length(st);  % Number of frames in the current v
         if pst == 0    % There is no frame started
             if lst == 1 
                part = length(v) - st+1;
                if part > 3
                    nT = v(st+3,1)/10;
                end
                nlines = nT*5 + d; %Number total of lines in this frame
                M = zeros(nlines,1);
                M(1:part,1) = v(st:end,1);
                msli = nlines - part;   % Number of missing lines in the current frame
                if msli > 0
                     pst = 1; % It means the frame started but is incomplete
                else
                    pst = 0; % It means this frame is complete
                    Update_Diagram(M(:,1),nT);
                end
             elseif lst > 1 % In this case, at least one frame is complete
                 for j = 1:lst-1
                     nT = v(st(j)+3,1)/10;  % Extract the number of targets
                     nlines = nT*5 + d; %Number total of lines in this frame
                     M = zeros(nlines,1);
                     M(1:nlines,1) = v(st(j):st(j+1)-1);
                     Update_Diagram(M(:,1),nT);
                 end
                 % Now analyzing the last frame, that can be either
                 % complete or incomplete
                part = length(v) - st(end)+1; %Length of the partial frame
                if part > 3
                    nT = v(st(end)+3,1)/10;
                    nlines = nT*5 + d; %Number total of lines in this frame
                    M = zeros(nlines,1);
                end
                M(1:part,1) = v(st(end):end,1);
                msli = nlines - part;   % Number of missing lines in the incomplete frame
                if msli > 0
                     pst = 1; % It means the frame started but is incomplete
                else 
                    pst = 0; % It means this frame is complete
                    Update_Diagram(M(:,1),nT);
                end
             end
         else % It means, pst == 1, or the first frame is the rest of the last one
             if lst == 0 % The frame is incomplete, and there is no located frame start in this packet
                % Then all this packet belongs to the current frame:
                M(part+1:part+length(v),1) = v(1:end,1);
                msli = msli - length(v);
                if msli > 0
                    pst = 1; % It means the frame started but is incomplete
                else
                    pst = 0; % It means this frame is complete
                    Update_Diagram(M(:,1),nT);
                end
             elseif lst == 1 % The first part corresponds to the last frame
                 M(part+1:part+st-1,1) = v(1:st-1,1);
                 part = length(v) - st+1;
                if part > 3
                    nT = v(st+3,1)/10;
                end
                nlines = nT*5 + d; %Number total of lines in this frame
                M = zeros(nlines,1);
                M(1:part,1) = v(st:end,1);
                msli = nlines - part;   % Number of missing lines in the current frame
                if msli > 0
                     pst = 1; % It means the frame started but is incomplete
                else
                    pst = 0; % It means this frame is complete
                    Update_Diagram(M(:,1),nT);
                end
             else %lst >1   % The first part corresponds to the missing frame
                 M(part+1:part+st(1)-1,1) = v(1:st(1)-1,1);
                 for j = 1:lst-1
                     nT = v(st(j)+3,1)/10;  % Extract the number of targets
                     nlines = nT*5 + d; %Number total of lines in this frame
                     M = zeros(nlines,1);
                     M(1:nlines,1) = v(st(j):st(j+1)-1);
                     Update_Diagram(M(:,1),nT);
                 end
                 % Now analyzing the last frame, that can be either
                 % complete or incomplete
                part = length(v) - st(end)+1; %Length of the partial frame
                if part > 3
                    nT = v(st(end)+3,1)/10;
                    nlines = nT*5 + d; %Number total of lines in this frame
                    M = zeros(nlines,1);
                end
                M(1:part,1) = v(st(end):end,1);
                msli = nlines - part;   % Number of missing lines in the incomplete frame
                if msli > 0
                     pst = 1; % It means the frame started but is incomplete
                else 
                    pst = 0; % It means this frame is complete
                    Update_Diagram(M(:,1),nT);
                end
             end
         end
      
     if k == np
        flg = 1; 
     end
     k = k+1;
 end

 
 %% Disconnect
 
% Disconnect and clean up the server connection. 
fwrite(t,'GBYE');
fclose(t); 
delete(t); 
clear t 