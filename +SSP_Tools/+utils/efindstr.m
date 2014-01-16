% indices = efindstr(string1, string2)
% 
% This function is an enhancement of MATLAB's findstr. If one string is
% not located within the other, instead of returning an empty matrix, this
% function will return 0. 
% 
% This is to make it easier to write things like this:
% 
% stringArray = { 'string1', 'string2', 'string3', 'string4' };
% if any( cellfun(@(str) efindstr(inputStr, str), stringArray) )
%    fprintf('%s is a valid string\n', inputStr)
% end
% 
function indices = efindstr(string1, string2)
	indices = findstr(string1, string2);
	if isempty(indices)
		indices = 0;
	end
end