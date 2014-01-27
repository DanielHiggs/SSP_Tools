function name = SelectFile(description, varargin)
% Return a valid name of a file/directory for output by continuously
% prompting the user to enter one.
%
% Parameters:
%
%     'type'   : 'file' or 'dir'. Specifies what the user is being asked
%                for and prompts accordingly.
%
%     'default': A default value to use if the user doesn't enter anything
%                at the prompt.
%
%

	p = inputParser();
	p.addParamValue('type', 'file');
	p.addParamValue('default', []);
	p.parse(varargin{:});
	
	type = p.Results.type;
	default = p.Results.default;
	
	function name = get_name()
		if isempty(default)
			prompt_str = sprintf('Select %s: ', description);
		else
			prompt_str = sprintf('Select %s [%s]: ', description, default);
		end
		name = input(prompt_str, 's');
		
		if isempty(name)
			name = default;
		end
	end
	
	
	while true
		name = get_name();
		
		% We're looking for a directory...
		if strcmp(type, 'dir')
			if ~exist(name, type)
				success = mkdir(name);
				if ~success
					fprintf('\nError creating directory. Please try again\n\n')
					continue;
				else
					break;
				end
			else
				yesno = input('That directory already exists. Overwrite? Y/N [Y]:', 's');
				if isempty(yesno) | (numel(yesno) == 1 & (yesno == 'Y' | yesno == 'y'))
					rmdir(name, 's');
					mkdir(name);
					break
				else
					continue
				end
			end
			
		% We're looking for a file...
		elseif strcmp(type, 'file')
			if ~exist(name, type)
				break
			else
				yesno = input('That file already exists. Overwrite? Y/N [Y]:', 's');
				if numel(yesno) == 1 & (yesno == 'Y' | yesno == 'y')
					break
				else
					continue
				end
			end
		end
	end
end
