# language: en


Feature: Configuration Loader

	In order to persist connection settings between program runs, I want to be
	able to read the configuration from a yaml file, providing reasonable 	
	defaults if settings are missing, and create a new file with reasonable 	
	defaults, if non exists.
	
 	Scenario: Configuration Loads on non-existent file 
		Given a non-existent config file name
		When loading the configuration
		Then create a default configuration file and exit
		
	Scenario: Configuration Loads successfully
		Given a request to load an existing config
		When loading the configuration
		Then I should have a populated global configuration hash
	
	@clean_temp_file
	Scenario: Configuration file is not valid yaml
		Given a corrupt config file
		When loading the configuration
		Then it should fail