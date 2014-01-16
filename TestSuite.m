clear all
close all

while true

	foo = SSP_Tools.Factories.TestFactory();
	bar = foo.select();
	bar.run();
	
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
	
	fprintf('Press any key to continue\n')
	pause


end