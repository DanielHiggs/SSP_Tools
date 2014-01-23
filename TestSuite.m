clear all
close all

while true

	foo = SSP_Tools.Factories.TestFactory();
	bar = foo.select();
	bar.run();
	
	commands = bar.get_commands();
	
	if isfield(commands, 'name') & any(strcmp({commands.name}, 'import'))
		yesno = input('\n\nImport This Data Into Current Workspace? [Y/N]: ', 's');
		if upper(yesno) == 'Y'
			[status, variables] = bar.import();
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
				prefix = input('\nEnter filename [*.mat]: ', 's');
				[status, files] = bar.save(prefix);
				if status ~= 1
					fprintf('Saving data to ./%s/\n\n', prefix);
					for i=1:numel(files)
						fprintf('%s\n', files{i});
					end
					fprintf('Done!\n\n');
					break
				else
					fprintf('%s Directory Already Exists\n', prefix);
					fprintf('Please enter a new directory\n');
				end
			end
		end
	end
	
	fprintf('Press any key to continue\n')
	pause


end