function truth = isLowerTriangular(A)
% 
% Returns true if matrix is lower triangular.
% 
	truth = 0;
	d = size(A,2);
	for i=0:d
		if any(diag(A,i) ~= 0)
			return
		end
	end
	truth = 1;
end