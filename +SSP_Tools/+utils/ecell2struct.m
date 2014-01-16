function outStruct = ecell2struct(inCell)

	m = length(inCell)/2;
	for i=1:2:m
		fieldName = inCell{i};
		fieldValue = inCell{i+1};
		outStruct.(fieldName) = fieldValue;
	end
	
end