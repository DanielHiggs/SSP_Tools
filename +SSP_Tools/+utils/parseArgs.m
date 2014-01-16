function argStruct = parseArgs( args, varargs )
% ARGSTRUCT = parseArgs( ARGS, VARARGS ) returns a structure containing fields for
% all of the named elements in VARARGS corresponding to names in ARGS
% 
% This is a helper function which allows functions to receive either a structure
% of options, or a name-value comma seperated list of options.
% 

	if length(varargs) == 1 && isstruct(varargs{1})
		% We were handed a structure
		argStruct = varargs{1};
		% Normalization
		for i=1:size(args,1)
			if isfield(argStruct, args{i,1})
				% Don't do anything
			else
				argStruct.(args{i,1}) = args{i,2};
			end
		end
	else
		% Assume we've been handed a name-value CSL
		p = inputParser;
		for i=1:size(args,1)
			addOptional(p, args{i,1}, args{i,2});
		end
		p.parse(varargs{:}); 
		argStruct = p.Results;
	end
end