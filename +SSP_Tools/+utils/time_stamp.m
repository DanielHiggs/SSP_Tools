function timestamp = time_stamp()

	time_now = clock;
	timestamp = sprintf('[%02.0f:%02.0f:%02.0f]', time_now(4:end));

end