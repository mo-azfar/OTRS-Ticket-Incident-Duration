# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
package Kernel::System::Ticket::Event::TicketIncidentDuration;

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use Data::Dumper;
use Fcntl qw(:flock SEEK_END);

our @ObjectDependencies = (
    'Kernel::System::Ticket',
    'Kernel::System::Log',
	'Kernel::System::Group',
	'Kernel::System::Queue',
	'Kernel::System::User',
	
);

=head1 NAME

Kernel::System::ITSMConfigItem::Event::DoHistory - Event handler that does the history

=head1 SYNOPSIS

All event handler functions for history.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $DoHistoryObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Event::DoHistory');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
	
	# check needed param
    if ( !$Param{TicketID} || !$Param{New}->{'StartField'} || !$Param{New}->{'EndField'} || !$Param{New}->{'IncidentTiming'}  || !$Param{New}->{'BusinessTiming'} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID || StartField || EndField || IncidentTiming || BusinessTiming for this operation',
        );
        return;
    }

    #my $TicketID = $Param{Data}->{TicketID};  ##This one if using sysconfig ticket event
	my $TicketID = $Param{TicketID};  ##This one if using GenericAgent ticket event
	
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	
	# get ticket content
	my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID,
		UserID        => 1,
		DynamicFields => 1,
		Extended => 0,
    );
	
	return if !%Ticket;
	
	#print "Content-type: text/plain\n\n";
	#print Dumper(\%Ticket);
		
	my $DateTimeObject1 = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String   => $Ticket{'DynamicField_'.$Param{New}->{'StartField'}},
        }
    );
	
	my $DateTimeObject2 = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String   => $Ticket{'DynamicField_'.$Param{New}->{'EndField'}},
        }
    );
	
	my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet(
        ID  => $Ticket{QueueID},
    );
	
	my %SLAData = $Kernel::OM->Get('Kernel::System::SLA')->SLAGet(
        SLAID  => $Ticket{SLAID},
		UserID => 1,
    );
	
	my $Calendar;
	#check calendar that has been used for this ticket
	if ($SLAData{Calendar})
	{
		$Calendar = $SLAData{Calendar};	
	}
	else
	{
		if ($Queue{Calendar})
		{
			$Calendar = $Queue{Calendar};
		}
		else 
		{
			$Calendar = 0;
		}	
	}
	
	my $Delta1;
	my $Delta2;
	
	#REF: https://doc.otrs.com/doc/api/otrs/6.0/Perl/Kernel/System/DateTime.pm.html#Delta
	if ( $Calendar )
	{
		#different in 24 hours
		$Delta1 = $DateTimeObject1->Delta( DateTimeObject => $DateTimeObject2, ForWorkingTime => 0, );
		#difference in working time
		$Delta2 = $DateTimeObject1->Delta( DateTimeObject => $DateTimeObject2, ForWorkingTime => 1, Calendar => $Calendar,);
	}
	else
	{
		#different in 24 hours
		$Delta1 = $DateTimeObject1->Delta( DateTimeObject => $DateTimeObject2, ForWorkingTime => 0, );
		#difference in working time
		$Delta2 = $DateTimeObject1->Delta( DateTimeObject => $DateTimeObject2, ForWorkingTime => 1,);	
	}
	
	my $incident_duration = "$Delta1->{Months} Month $Delta1->{Days} Days $Delta1->{Hours} Hours $Delta1->{Minutes} Minutes";
	my $business_impact = "$Delta2->{Hours} Hours $Delta2->{Minutes} Minutes";
	
	my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
	my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');
	
	my $DF01Get = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{New}->{'IncidentTiming'},
		);
		
	my $DF02Get = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{New}->{'BusinessTiming'},
		);	
	
	##update Total incident duration DF
	my $Success1 = $DynamicFieldValueObject->ValueSet(
        FieldID  => $DF01Get->{ID},                 # ID of the dynamic field
        ObjectID => $TicketID,                # ID of the current object that the field
                                              #   must be linked to, e. g. TicketID
        Value    => [
            {
                ValueText          => $incident_duration,            # optional, one of these fields must be provided
                #ValueDateTime      => '1977-12-12 12:00:00',  # optional
                #ValueInt           => 123,                    # optional
            },
            
        ],
        UserID   => 1,
    );
	
	##update business impact DF	
	my $Success2 = $DynamicFieldValueObject->ValueSet(
        FieldID  => $DF02Get->{ID},                 # ID of the dynamic field
        ObjectID => $TicketID,                # ID of the current object that the field
                                              #   must be linked to, e. g. TicketID
        Value    => [
            {
                ValueText          => $business_impact,            # optional, one of these fields must be provided
                #ValueDateTime      => '1977-12-12 12:00:00',  # optional
                #ValueInt           => 123,                    # optional
            },
            
        ],
        UserID   => 1,
    );
   
}

1;

