%% Program Init

close all; clc; clear all;

%% Initializing the Variables
 
Set = [0, 5, 25; 1, 10, 25; 2, 20, 25; 3, 50, 25; 4, 100, 25; 5, 200, 25; ...
    6,10,50; 7,20,50; 8,30,50; 9,100,50; 10,200,50; 11,50,100; 12,100,100; ...
    13,200,100; 14,200,185]; % Matrix of possible configurations of Range/Speed
TXSet = [0,-45;1,-25; 2,-15; 4,-10; 7,-5; 11,0; 20,5; 37,10; 63,15];

limit = 10000; % Number of frames to be collected

 RXGain = 44; % Receiver Gain
 TXAN = 2; % Transmitter antenna number
 RSSR = 2; % Range and Speed Settings
 MSG = {'52414443', '52444441', '52415244', '50444154', '444f4e45', '54444154', '5250524d'};
 % Possible active messages: RADC, RDDA, RARD, PDAT, DONE, TDAT and RPRM
 
%% Define the TCP/IP connection

% Create TCP/IP object 't'. Specify server machine and port number. 
t = tcpip('192.168.100.5', 6172); 

% Set size of receiving buffer, if needed. 
set(t, 'InputBufferSize', 1024); 

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
 
RPRM_8b = zeros(size(RPRM,1),2); % Initialize one vector to receive the RPRM in 8 bits
C = clock; % Collect the time of the start of this program
fname = sprintf('C:\\Users\\Charles\\Documents\\RFbeam\\MR3003\\Record_%04d-%02d-%02d_%02d-%02d-%02d.bin', C(1:5), round(C(6)));
fid = fopen(fname, 'w'); % Open the bin file in the writing mode
RPRM_8b(:,1) = floor(RPRM./256); % Convertion from 16 to 8 bits
RPRM_8b(:,2) = rem(RPRM,256);
RPRM_8b = reshape(RPRM_8b',size(RPRM_8b,1)*size(RPRM_8b,2),1); % From two columns, write all in a single column
RPRM_8b(38,1) = RPRM_8b(38,1) + 1; % Add one to the number of the first frame (necessary to run the file in the RFBeam software).
fwrite(fid,RPRM_8b); % Write the RPRM to the bin file
fwrite(fid,0,'int16'); % Add some complementary bytes
fwrite(fid,4,'int8');
fwrite(fid,0,'int16');
fwrite(fid,0,'int8'); % This line is only 0 if the first frame number is between 0 and 255
fwrite(fid,RPRM_8b(38,1)+1,'int8'); % Write the first frame number

  %% Data Streaming
  
bfsize = get(t,'InputBufferSize'); % Collect the buffer size
i = 1; % Initialize the while loop counter
FindFirst = 0; % Initialize the flag to detect first packet
nf = 0; % Initialize the frame counter

while sum(nf) <= limit % While the number of frames less than the expected...
    r(1 + (i-1)*bfsize:bfsize*i,1) = fread(t);    % Read the data 
    st = find(r(1 + (i-1)*bfsize:bfsize*i,1) == 80 & circshift(r(1 + (i-1)*bfsize:bfsize*i,1),[-1 0]) == 68);
    %Detect the frame start
    nf = nf + length(st); % Update the number of frames received
    if FindFirst == 0 % If the first frame doesn't appeared yet...
        if isempty(st) == 0 % If there's at least one frame in the current packet
           FindFirst = 1; % Then the first frame is selected
           ind = st(1); % And correspond to the first frame in this packet
        end
    end 
    i = i+1; % Update the loop iteration counter
end
r(1:ind-1) = []; % Remove the lines of the data before the first frame
if rem(length(r),2) == 0 % Ensure that the number of lines is odd
    r(end+1,1) = 0;
end
fwrite(fid,r); % Write the frames data to the .bin file
fwrite(fid,0,'int8'); % Just to make the length odd

 %% Disconnect

% Disconnect and clean up the server connection. 
fwrite(t,'GBYE'); % Stop the packets flow
fclose(t); % Close the connection
fclose(fid); % Close the .bin file
delete(t);  % Delete the connection data
clear t % clear t from the memory
