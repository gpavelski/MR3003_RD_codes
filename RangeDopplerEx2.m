%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
clc

c=3e8; %speed of light
fc=8e9; %carrier freq
deltaF=32e6; %sweep freq
T=1e-3; %one period
alph=deltaF/T; %sweep rate

R=500; %initial distance of the target
td=2*R/(c); %initial delay of returned signal

v=2; %speed of the target (give some value between 0 and 10)
D=64; % #of doppler cells OR #of sent periods
N=2^10; %for length of time

t=linspace(0,D*T,D*N); %total time

n=0;
nT=length(t)/D; %length of one period
a=zeros(1,length(t)); %transmitted signal
b=zeros(1,length(t)); %received signal
r_t=zeros(1,length(t));
ta=zeros(1,length(t));
r1=R;
f0=fc;
for i=1:length(t)

      r_t(i)=r1+v*t(i); % range of the target in terms of its velocity and initial range
      ta(i)=2*r_t(i)/c; % delay for received signal

      if i>n*nT && i<=(n+1)*nT % doing this for D of periods (nt length of pulse)

          a(i)=sin(2*pi*(f0*t(i)+.5*alph*t(i)^2-alph*t(i)*n*T)); %transmitted signal
          b(i)=sin(2*pi*(f0*(t(i)-ta(i))+.5*alph*(t(i)-ta(i))^2-alph*(t(i)-ta(i))*n*T)); %received signal

      else

          n=n+1
          a(i)=sin(2*pi*(f0*t(i)+.5*alph*t(i)^2-alph*t(i)*n*T)); %transmitted signal
          b(i)=sin(2*pi*(f0*(t(i)-ta(i))+.5*alph*(t(i)-ta(i))^2-alph*(t(i)-ta(i))*n*T)); %received signal

      end

end

mixed1=(a.*b); %video signal OR IF signal (output of mixer)

m1=reshape(mixed1,length(mixed1)/D,D); %generating matrix ---> each row showing range info for one period AND each column showing number of periods

[My,Ny]=size(m1');

win=hamming(Ny);
m2=conj(m1).*(win*ones(1,My)); %taking conjugate and applying window for sidelobe reduction (in time domain)

Win=fft(hamming(My),D);
M2=(fft(m2,2*N)); %First FFT for range information

M3=fftshift(fft(M2',2*D)); %Second FFT for doppler information

[My,Ny]=size(M3);
doppler=linspace(-D,D,My);
range=linspace(-N,N,Ny);

figure;contour(range,doppler,abs(M3));grid on
xlabel('Range')
ylabel('Doppler')

figure;mesh(range,doppler,abs(M3))
xlabel('Range')
ylabel('Doppler')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
