# language: en

Feature: Program Exit Via INT Signal

	In order to provide a safely net that prevents users from accidentally
	exiting the RubOt, trap the INT signal
	
 	Scenario: User presses ^C the first time 
		Given the program was run normally
		When the program is sent an INT Signal
		Then tell the user to press ^C again
		And do not quit
		
	Scenario: User presses ^C twice
		Given the program was run normally
		When the program is sent an INT Signal twice
		Then quit
		
	Scenario: User presses ^C twice with more than 10 seconds between 
		Given the program was run normally
		When the program is sent an INT Signal
		And "10" seconds elapse
		And the program is sent an INT Signal
		Then quit
