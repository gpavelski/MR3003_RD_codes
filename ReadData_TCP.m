close all;

k = find(s(:,1) == 21572); % Find the indexes relative to the start of each frame
df = diff(k); % Compute the difference of the vector k subsequent elements
MnT = (max(df)-10)/5; %Maximum number of targets
M = zeros(max(df),length(df));  %Initialize the matrix M containing all the frames
cct = zeros(size(df,1),1);
r_t = zeros(MnT,length(df));
v_t = r_t;
theta_t = r_t;

for i = 1:length(df)    % For each frame...
   M(1:df(i),i) = s(k(i):k(i)+df(i)-1,1);   % Extract the frame i from C to the column i of M
   
   for j = 1:M(4,i)/10
         r_t(j,i) = M(5 + (j-1)*5,i);
         v_t(j,i) = M(6 + (j-1)*5,i);
         if M(7 + (j-1)*5,i) > 60000
             theta_t(j,i) = (M(7 + (j-1)*5,i) - 65536)*360/(2*pi)/100;
         else
            theta_t(j,i) = (M(7 + (j-1)*5,i))*360/(2*pi)/100;   
         end

   end
end

for k = 1:size(r_t,1) % Plot the curves for each target
    figure(1);
    plot(r_t(k,:));
    hold on;
    
    figure(2);
    plot(theta_t(k,:));
    hold on;
end

figure(1);
title('Range x Targets');
xlabel('Frame');
ylabel('Range [cm]');
figure(2);
title('Angle x Targets');
xlabel('Frame');
ylabel('Angle [°]');

%% Range-Range Diagram

h = cell(1,size(r_t,1));
figure(4);
for i = 1:size(r_t,1)
h{i} = scatter(NaN, NaN,'filled'); %// empty plot
hold on
end
title('Range-Range Diagram');
axis([-50*5 50*5 0 100*5]);
xlabel('Range X [cm]');
ylabel('Range Y [cm]');
grid on;
axis manual %// this line freezes the axes

for j = 1:size(r_t,2)
    for i = 1:size(r_t,1)
        set(h{i}, 'XData', -r_t(i,j)*sind(theta_t(i,j)), 'YData', r_t(i,j)*cosd(theta_t(i,j)));
    end
    pause(0.01);
end

