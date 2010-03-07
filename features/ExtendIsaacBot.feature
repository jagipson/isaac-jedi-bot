# language: en

Feature: Extend Isaac::Bot with off() method

	In order to remove items in Isaac::Bot's $events data structure
	That were added using the on() method
	I want to extend the Isaac::Bot object to have and off() method
	
	# We don't test adding events (that's Isaac test suite's job)	
		
	Scenario: successful removal of an event
		Given an extended bot 
		When it has a "foo" "channel" event
		When it has a "foo" "private" event
		When I remove the "foo" "channel" event
		Then it responds to the "foo" "private" event
		But it does not respond to the "foo" "channel" event
	
	Scenario: removal of a non-existent event
		Given an extended bot
		Then no exception should be thrown if I remove a non-existent event
