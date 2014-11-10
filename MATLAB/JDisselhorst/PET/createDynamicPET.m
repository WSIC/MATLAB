function [t, bloodCurve, tissueCurve] = createDynamicPET(tau1, tau2, ...
    A1, l1, A2, l2, A3, l3, AC, ACt, K1, k2, k3, k4, Vb, res, TMax)

    a = (A1+A2+A3)/(tau2-tau1);   %Slope of input curve
    alpha1=0.5*(k2+k3+k4-sqrt((k2+k3+k4)^2-4*k2*k4));
    alpha2=0.5*(k2+k3+k4+sqrt((k2+k3+k4)^2-4*k2*k4));
    t = 0:res:TMax; %Time-axis
    %----------------------------- Create arterial plasma time activity curve.
    NAPTAC0=zeros(1,length(0:res:tau1-res));
    NAPTAC1=a.*([tau1:res:tau2-res]-tau1);
    NAPTAC2=A1*exp(-l1*([tau2:res:TMax]-tau2))+A2*exp(-l2*([tau2:res:TMax]-tau2))+A3*exp(-l3*([tau2:res:TMax]-tau2));
    NAPTAC2=(NAPTAC2>0).*NAPTAC2;
    NAPTAC=[NAPTAC0, NAPTAC1, NAPTAC2];
    Q=AC./NAPTAC(find(t>=ACt,1,'first'));APTAC=Q.*NAPTAC; clear NAPTAC NAPTAC0 NAPTAC1 NAPTAC2
    if length(t)>length(APTAC)
        APTAC = [0 APTAC];
    end
    %----------------------------- Create tissue time activity curve
    VoorFree=(K1/(alpha2-alpha1))*((k4-alpha1)*exp(-alpha1*t)+(alpha2-k4)*exp(-alpha2*t));
    VoorBound=((K1*k3)/(alpha2-alpha1))*(exp(-alpha1*t)-exp(-alpha2*t));
    ACfree=ifft(fft([VoorFree zeros(1,length(APTAC)-1)]).*fft([APTAC zeros(1,length(VoorFree)-1)]))*res;
    ACbound=ifft(fft([VoorBound zeros(1,length(APTAC)-1)]).*fft([APTAC zeros(1,length(VoorBound)-1)]))*res;
    ACfree=ACfree(1:size(t,2));ACbound=ACbound(1:size(t,2));
    TTAC=((1-Vb).*(ACfree+ACbound))+(Vb.*APTAC);
    
    bloodCurve = APTAC;
    tissueCurve = TTAC;
    
end