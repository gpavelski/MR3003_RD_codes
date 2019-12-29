
%% Program init

clear all; close all; clc; 


%% Opening the saved file

fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_Only_TDAT\Record_2018-10-23_15-30-42.bin','rb');
% open the file on Matlab
C=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file


fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_Only_TDAT\Record_2018-10-23_15-29-52.bin','rb');
% open the file on Matlab
D=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file


fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_Only_TDAT\Record_2018-10-23_15-29-13.bin','rb');
% open the file on Matlab
E=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file

fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_Only_TDAT\Record_2018-10-23_15-29-52.bin','rb');
% open the file on Matlab
F=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file

fid = fopen('C:\Users\Charles\Documents\RFbeam\MR3003\Record_Only_TDAT\Record_2018-10-23_15-30-42.bin','rb');
% open the file on Matlab
G=fread(fid, 'uint16');  %Extract the information contained in this file
fclose(fid); % close the file

H(1:length(C),1) = C;
H(1:length(D),2) = D;
H(1:length(E),3) = E;
H(1:length(F),4) = F;
H(1:length(G),5) = G;

for i = 1:length(H)
   if isequal(H(i,1),H(i,2),H(i,3),H(i,4),H(i,5)) == 1
       H(i,6) = 1;
   end
   H(i,7) = issorted(H(i,1:5),'descend') + issorted(H(i,1:5));
end

V = find(H(:,7) == 1);
J = H(V,:);