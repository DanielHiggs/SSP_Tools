function str = cell2str(inputCell)
% Converts a cell array into a textual representation of that cell array
% that is suitable for output to the console.
% 
% MATLAB probably has something like this, but I can't find it.
% 
	strVals = {};
	for i=1:length(inputCell)
		strVals{end+1} = SSP_Tools.utils.any2str(inputCell{i});
	end
	
	str = ['{', sprintf(' %s, ', strVals{1:end-1}), sprintf('%s ', strVals{end}), '}'];

end