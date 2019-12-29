function [RPRM] =  RPRM_Collect(t)

 st = [];   % Initialize the vector to detect frame start
 RPRM = zeros(33,1);    % Initialize the RPRM vector
 
 RModeD = char(sscanf(['44534630' '00000004' '5250524d'],'%2X').'); %DSF0 Disable RPRM
 RModeE = char(sscanf(['44534631' '00000004' '5250524d'],'%2X').'); %DSF1 Enable RPRM

fwrite(t,RModeE);   % Enable RPRM segment
len = 256;  % Define the length of the message read in each iteration
while isempty(st) == 1 || st(1)+32 > len/2  
    r = fread(t,len);    % Read the data
    v(1:len/2,1) =  256*r(1:2:end-1,1) + r(2:2:end,1); % Convert data to int16 
    st = find(v == 21072); % Positions relative to start of each frame
    if isempty(st) == 0 && st(1)+32 < len/2  % If one frame is detected
        RPRM(1:33,1) = v(st(1):st(1)+32,1); % Stores RPRM information
    end
end
fwrite(t,RModeD); % Disable RPRM Mode