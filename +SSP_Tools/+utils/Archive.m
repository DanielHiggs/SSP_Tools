classdef Archive < handle
% A simple wrapper for MATLAB's containers.Map which implements
% a simple database for automatically archiving data to disk.  

	properties
		directory = [];
		pattern = [];
		data = [];
	end
	
	methods
	
		function obj = Archive(directory, pattern, varargin)
			obj.directory = directory;
			obj.pattern = pattern;
			
			obj.data = containers.Map;
			
			if exist(obj.directory, 'dir')
			% If the directory exists, read in all the files
			
				files = dir([obj.directory, '/*.mat']);
			
				for filename={files.name}
					
					filename = filename{1};
					
					if strcmp(filename, '.') | strcmp(filename, '..')
						continue
					end
														
					% Get the data's key from the filename by parsing it
					% with the same fprintf format string it was created with
					id = sscanf(filename, obj.pattern)';
					
					% Run that id through our hashing function
					hash = SSP_Tools.utils.DataHash(id);
					
					% Load the data from the file
					record_data = load([obj.directory, '/', filename]);
					
					% Use the hash to store the file in-memory.
					obj.data(hash) = record_data;
				end
			else
			% If the directory doesn't exist, create it.
				mkdir(obj.directory)
			end
		end
		
		function record = get(obj, m)
		% Obtain a record "m" from collection_name
			
			if ischar(m)
			% m has been specified as a string format that's defined by
			% obj.pattern. Parse it.
				id = ffscanf(obj.pattern, m);
			else
			% m is already in the format we use for hashing.
				id = m;
			end
			
			% Produce a hash from our record name
			hash = SSP_Tools.utils.DataHash(id);
			
			if obj.data.isKey(hash)
			% A corresponding record exists in our database
				record = obj.data(hash);
			else
				record = [];
			end
		end
		
		function store(obj, m, v, varargin)
		% Store a record m in collection_name
		
			if numel(varargin) > 0
				log = varargin{1};
			else
				log = [];
			end
		
			if ischar(m)
			% m has been specified as a string format that's defined by
			% obj.pattern. Parse it.
				id = ffscanf(obj.pattern, m);
			else
			% m is already in the format we use for hashing.
				id = m;
			end
			
			% Produce a hash from our record name
			hash = SSP_Tools.utils.DataHash(id);			
			
			% Record it in memory			
			obj.data(hash) = v;
			
			% Write a logfile to disk
			if ~isempty(log)
				v.log = log;
				logname = sprintf([obj.directory, '/', obj.pattern, '.txt'], id);
				fid = fopen(logname, 'w');
				cellfun(@(line) fprintf(fid, line), log);				
			end
						
			% Record it to disk
			filename = sprintf([obj.directory, '/', obj.pattern, '.mat'], id);
			save(filename, '-struct', 'v');
			
		end
	end
end