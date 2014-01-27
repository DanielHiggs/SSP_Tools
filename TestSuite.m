clear all
close all

while true

	% Create an instance of the TestFactory to manage
	% available available tests.
	TestFactory = SSP_Tools.Factories.TestFactory();
	 
	% Get the available tests
	available_tests = TestFactory.available_tests;
	
	% Append a 'quit' option
	available_tests(end+1) = struct('name', 'quit', 'longname', 'Quit', 'class', false, 'parameters', false);
	
	
	% Print out the available tests.
	for i=1:numel(available_tests)
		fmt = '[%i] %s\n';
		fprintf(fmt, i, available_tests(i).longname);
	end
	
	% Select a test
	n = input('\nSelect a Test: ');
	if strcmp(available_tests(n).name, 'quit');
		fprintf('Goodbye!\n\n');
		break
	else
		test_name = available_tests(n).name;
		test = TestFactory.select('name', test_name);
	end
	
	% Run the test.
	test.run();
	
	% Find out what post-test commands ('save data to disk', 'import data to workspace', etc)
	% are available
	commands = test.get_commands();
	
	if isfield(commands, 'name') & any(strcmp({commands.name}, 'import'))
		yesno = input('\n\nImport This Data Into Current Workspace? [Y/N]: ', 's');
		if upper(yesno) == 'Y'
			[status, variables] = test.import();
			if status ~= 1
				for variable=variables
					fprintf('Saving %s to variable ''%s''\n', variable.description, variable.name);
				end
				fprintf('Done!\n\n');
			end
			break
		end
	end
	
	if isfield(commands, 'name') & any(strcmp({commands.name}, 'save'))
		yesno = input('\n\nSave This Data? [Y/N]: ', 's');
		if upper(yesno) == 'Y'
			while true
			
				prefix = SSP_Tools.utils.SelectFile('a directory to save data to', ...
				                                     'type', 'dir', ...
				                                     'default', sprintf('output-%s', datestr(now)));
				 
				prefix
				[status, files] = test.save(prefix);
				if status ~= 1
					fprintf('Saving data to ./%s/\n\n', prefix);
					for i=1:numel(files)
						fprintf('%s\n', files{i});
					end
					fprintf('Done!\n\n');
					break
				end
			end
		end
	end
	
	fprintf('Press any key to continue\n')
	pause


end