% match = matchString(string1, string2)
%
% This function compares two strings and returns true if they are alike
% 
function match = matchString(string1, string2)
	match = false;
	if length(string1) == length(string2) && all(string1 == string2)
		match = true;
	end
end