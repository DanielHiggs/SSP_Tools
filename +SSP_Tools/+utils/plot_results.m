function plot_results(x,u,x_exact, u_exact)
	plot(x,u);
	hold on;
	plot(x_exact,u_exact,'r');
	hold off
	pause(0.01);
end