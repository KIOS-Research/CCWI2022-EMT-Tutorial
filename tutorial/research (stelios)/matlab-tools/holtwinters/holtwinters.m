function  [ forecasts]= holtwinters(y,L,m)
% y is the array on which it will be applied
% alpha , beta, gamma - exponential smoothing coefficients 
% for level, trend, seasonal components.
% A complete season's data consists of L periods. And we need to estimate the trend factor from one
% period to the next. To accomplish this, it is advisable to use two complete seasons; that is, 2L 
% periods.
% m is the number of future points we will estimate
% reference: http://www.itl.nist.gov/div898/handbook/pmc/section4/pmc435.htm


alpha=0.9;
beta=0.0;
gamma=0.2;

%Initial values

%First exponential smoothed value
S1=y(1,1);

%Trend factor

tot=0;
for i=1:L
    tot=tot+y(L+i)-y(i);
end

b=tot*(1/L)^2;

%Seasonal factors
ylen=size(y,1);
seasons=floor(ylen/L);

seasonaverage=zeros(seasons,1);
averagedobs=zeros(seasons,1);
I=zeros(L,1);

for i=1:seasons
   for j=1:L
      
       seasonaverage(i,1)=seasonaverage(i,1)+y((i-1)*L+j);
   end
    seasonaverage(i,1)=seasonaverage(i,1)/L;
end

for i=1:seasons
   for j=1:L
        averagedobs((i-1)*L+j,1)=y((i-1)*L+j)/seasonaverage(i,1);
   end
   
end

for i=1:L
   for j=1:seasons
        I(i,1)=I(i,1)+averagedobs((j-1)*L+i);
   end
   I(i,1)=I(i,1)/seasons;
end


St=zeros(ylen,1);
bt=zeros(ylen,1);
It=zeros(ylen,1);
Ft=zeros(ylen+m,1);

St(1,1)=S1;
bt(1,1)=b;
for i=1:L
    It(i,1)=I(i,1);
end




for i=2:ylen

%Calculate exponential smoothing
    if (i-1>=L)
        St(i,1)=alpha*y(i,1)/It(i-L,1) + (1-alpha)*(St(i-1,1) + bt(i-1,1));
    else
        St(i,1)=alpha*y(i,1) + (1-alpha)*(St(i-1,1) + bt(i-1,1));
    end
    
%Calculate trend smoothing
    bt(i,1)=(St(i,1)-St(i-1,1))*gamma + (1-gamma)*bt(i-1,1);
    
%Calculate seasonal smoothing
if (i-L>0)
    It(i,1)=beta*y(i,1)/St(i,1) + (1-beta)*It(i-L,1);
end
    
%Calculate forecasts
    if (i+m-1>=L)
        Ft(i+m,1)=(St(i,1)+m*bt(i,1))*It(i-L+m);
    end

end
 
%disp(Ft);

t=1:ylen+m;

figure;plot(y,'b');hold on;
plot(t,Ft,'r*');

forecasts=Ft;

str=sprintf('forecast for next value:%f',forecasts(end,1));
disp(str);
