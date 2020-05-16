# OTRS-Ticket-Incident-Duration  
- Built for OTRS CE 6.0.x  
- Calculate the difference between 2 ticket dynamic field datetime field, in full hours and business working time.  

1. Create 2 additional dynamic field ticket (text) to store the calculation value
  
		IncidentDuration  
		BusinessImpactDuration  

2. Admin must create a new Generic Agent (GA).  

	Example: 
 
		Name => Update Incident Duration and Business Impact Duration DF
		Event Based Execution => TicketCreate or TicketStateUpdate or Any Ticket Event
		Select Tickets => TicketNumber = *
		Execute Custom Module => 
			Module 			=> Kernel::System::Ticket::Event::TicketIncidentDuration
			StartField 		=> **Ticket DF Name of start datetime
			EndField		=> **Ticket DF Name of end datetime
			IncidentTiming	=> IncidentDuration
			BusinessTiming	=> BusinessImpactDuration


[![df1.png](https://i.postimg.cc/mk97r6M1/df1.png)](https://postimg.cc/PvtC3ySd)  

[![df2.png](https://i.postimg.cc/qB6sQgYB/df2.png)](https://postimg.cc/s1yGgfsb)  