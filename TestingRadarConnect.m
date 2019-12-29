%UNTITLED2 Code for communicating with an instrument.
%
%   This is the machine generated representation of an instrument control
%   session. The instrument control session comprises all the steps you are
%   likely to take when communicating with your instrument. These steps are:
%   
%       1. Create an instrument object
%       2. Connect to the instrument
%       3. Configure properties
%       4. Write and read data
%       5. Disconnect from the instrument
% 
%   To run the instrument control session, type the name of the file,
%   untitled2, at the MATLAB command prompt.
% 
%   The file, UNTITLED2.M must be on your MATLAB PATH. For additional information 
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command 
%   prompt.
% 
%   Example:
%       untitled2;
% 
%   See also SERIAL, GPIB, TCPIP, UDP, VISA, BLUETOOTH, I2C, SPI.
% 
 
%   Creation time: 21-Jul-2017 23:05:12

% Find a serial port object.

close all;

obj1 = instrfind('Type', 'tcpip', 'Name', 'TCPIP-192.168.100.5','Status','Open');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = tcpip('192.168.100.5', 6172, 'NetworkRole', 'server');
else
    fclose(obj1);
end


fopen(obj1);
% Configure instrument object, obj1.
%set(obj1, 'BaudRate', 460800);

% Communicating with instrument object, obj1.
%data1 = query(obj1, '$A02');

% Disconnect from instrument object, obj1.
fclose(obj1);

% Clean up all objects.
delete(obj1);