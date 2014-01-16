% estruct2cell(structure)
%
% Converts a structure to a cell array where the fieldnames and values
% are interposed. 
% 
% Example:
%
% foo.bar = 42;
% foo.moo = 'hello';
% foo.baz = [1,2,3,4,5];
%
% m = estruct2cell(foo);
%
% Produces:
%
% m = { 'bar', 42, 'moo', 'hello', 'baz', [1,2,3,4,5] }
% 
% This was written so I can take the output of the Unmatched field inputParser gives
% and feed it into another function that accepts arguments parsed by inputParser
% 
% D. Higgs 2012

function cellarray = estruct2cell(structure)

	if length(structure) > 1
		error('We don''t do structure arrays yet--sorry');
	end

	fields = fieldnames(structure);
	values = struct2cell(structure);
	
	cellarray = {};
	
	for i=1:length(fields)
		cellarray{end+1} = fields{i};
		cellarray{end+1} = values{i};
	end
end
