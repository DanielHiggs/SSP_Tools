%for s=p
%tab2p=tabLINEAR(5:10,2:7)
%tab3p=tab3p(5:10,3:8)
%tab4p=tab4p(5:10,2:7)
for j=1:6
    xx1(j)=4+j;
     Rpp2(j)=tab2p(j,j);
     Rpp3(j)=tab3p(j,j);
     Rpp4(j)=tab4p(j,j);
end
plot(xx1,Rpp2,'r','linewidth',1)
xlim([4.5,10.5])
ylim([0,10])
hold on
plot(xx1,Rpp4,'rp:','linewidth',1)
for j=2:6
      xx2(j)=3+j;
     Rpq2(j-1)=tab2p(j,j-1);
     Rpq3(j-1)=tab3p(j,j-1);
     Rpq4(j-1)=tab4p(j,j-1);
end
plot(xx2,Rpq2,'b','linewidth',1)
plot(xx2,Rpq4,'bp:','linewidth',1)
for j=3:6
     Rpr2(j-2)=tab2p(j,j-2);
     Rpr3(j-2)=tab3p(j,j-2);
     Rpr4(j-2)=tab4p(j,j-2);
end
plot(xx1,Rpr2,'g','linewidth',1)
plot(xx1,Rpr4,'gp:','linewidth',1)
for j=4:6
     Rps2(j-3)=tab2p(j,j-3);
     Rps3(j-3)=tab3p(j,j-3);
     Rps4(j-3)=tab4p(j,j-3);
end
plot(xx1,Rps2,'m','linewidth',1)
plot(xx1,Rps4,'mp:','linewidth',1)
for j=5:6
     Rpt2(j-4)=tab2p(j,j-4);
     Rpt3(j-4)=tab3p(j,j-4);
     Rpt4(j-4)=tab4p(j,j-4);
end
plot(xx1,Rpt2,'c','linewidth',1)
plot(xx1,Rpt4,'gc:','linewidth',1)
% 
% tab4pB=tab4p(5:10,5:10);
% plot(tab3pB(:,1), tab4pB(:,3),'r--','linewidth',2)
% hold on
% plot(tab3pB(:,1), tab4pB(:,2),'b--','linewidth',2)
% plot(tab3pB(:,1), tab4pB(:,4),'g--','linewidth',2)
% plot(tab3pB(:,1), tab4pB(:,5),'m--','linewidth',2)
% plot(tab3pB(:,1), tab4pB(:,6),'c--','linewidth',2)