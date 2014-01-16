function str = any2str(input)

	if isstr(input)
		str = sprintf('''%s''', input);
	elseif isnumeric(input)
		if isinteger(input)
			str = sprintf('%i', input);
		else
			str = sprintf('%0.5g', input);
		end
	end
	

end