function table = checkall(p)
s = dir(['*', 'pLINEAR.mat']);
%s = dir(['*', int2str(p),'pLNL.mat']);
S = struct2cell(s);
si = size(S);
table = zeros(10,5);
for j=1:si(2)
	M = load(S{1,j});
	r(j) = M.r;
	re(j) = r(j)/M.s;
	info(j) = M.info
	%[rn(j),r(j),info(j)] = checkpush2(S{1,j});
	if info(j) > 0
		table(M.s,M.p) = r(j);
	end
end
table(:,1) = 1:size(table,1);
table(1,:) = 1:size(table,2);
%r
%rn
%for j=1:si(2)
%	disp([ num2str(re(j)), ' - ' , num2str(r(j)), ' - ' , num2str(info(j)), ' - ', S{1,j}]);
%end
table(:,2:4)=[];
table(13:15,:)=[];