function watch_movie(file)

load(file);

for i=1:length(U)
	plot(x,U{i})
	hold all
	plot(x,U_EXACT{i},'r')
	hold off
	clf
	pause(0.01);
end

end