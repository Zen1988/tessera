package Kernel::System::TESSERA::RiskGovernanceDecision;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Kernel::System::ZTSMBlueBookRuntime ();
use Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume ();
use Kernel::System::TESSERA::RiskRegister ();
our @ObjectDependencies = qw(Kernel::System::Ticket Kernel::System::Service Kernel::System::DynamicField Kernel::System::DynamicField::Backend Kernel::System::GovernanceObject Kernel::System::PID Kernel::System::Log Kernel::System::State Kernel::System::GeneralCatalog);
sub new {return bless {},$_[0]}
sub _Scalar {return Kernel::System::TESSERA::RiskRegister::ScalarValue($_[0])}
sub _BookRecords {
    my ($ID)=@_;
    return if !$ID;
    my $Book=Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(BlueBookID=>$ID);
    return if ref $Book ne 'HASH';
    my @Rows=Kernel::System::ZTSMBlueBookRuntime::RecordsParse(BlueBook=>$Book);
    return if !@Rows || grep {!$_->{Type}} @Rows;
    return \@Rows;
}
sub _HasApproval {
    my ($Rows,$Seen)=@_;
    return if !$Rows;
    return 1 if grep {$_->{Type} eq 'Approval'} @{$Rows};
    for my $Row (@{$Rows}) {
        my $ID=_Scalar($Row->{PurpleBook});
        next if !$ID;
        return if $Seen->{$ID}++;
        my $Nested=_BookRecords($ID);
        my $Result=_HasApproval($Nested,$Seen);
        return if !defined $Result;
        return 1 if $Result;
    }
    return 0;
}
sub FromCompletedLevel {
    my ($Self,%P)=@_;
    my $T=$P{Ticket}||{};
    return 1 if ($T->{Type}||'') ne 'ServiceRequest' || _Scalar($T->{'DynamicField_ZTicket-Parent'});
    my %Service=$Kernel::OM->Get('Kernel::System::Service')->ServiceGet(ServiceID=>$T->{ServiceID},UserID=>1);
    return 1 if ($Service{Name}||'') ne 'Risk::Management';
    my $StateBookID=_Scalar($T->{'DynamicField_ZTicket-StateBook'});
    return 1 if !$StateBookID;
    my $Book=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$StateBookID,DynamicFields=>1,UserID=>1);
    return 1 if ref $Book ne 'HASH';
    my @Records=Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume::_RecordsParse(StateBook=>$Book);
    my @Indexes=grep {(_Scalar($Records[$_]{BlueBook})||'') eq ($P{BlueBookID}||'') && ($Records[$_]{State}||'') eq ($T->{State}||'')} 0..$#Records;
    return 1 if @Indexes!=1;
    return $Self->Run(Ticket=>$T,Records=>\@Records,CurrentIndex=>$Indexes[0]);
}
sub Evidence {
    my ($Self,%P)=@_;
    my $T=$P{Ticket}||{};
    return if ($T->{Type}||'') ne 'ServiceRequest' || _Scalar($T->{'DynamicField_ZTicket-Parent'});
    my %Service=$Kernel::OM->Get('Kernel::System::Service')->ServiceGet(ServiceID=>$T->{ServiceID},UserID=>1);
    return if ($Service{Name}||'') ne 'Risk::Management';
    my $Current=$P{Records}[$P{CurrentIndex}]||{};
    my $BookID=_Scalar($Current->{BlueBook});
    my $Rows=_BookRecords($BookID);
    return if !$Rows || !grep {$_->{Type} eq 'Approval'} @{$Rows};
    # Final approval is determined by the StateBook's remaining Books, not a
    # fixed state name, queue, chapter number or role routing.
    for my $Index ($P{CurrentIndex}+1 .. $#{$P{Records}}) {
        my $NextID=_Scalar($P{Records}[$Index]{BlueBook});
        next if !$NextID;
        my $Next=_BookRecords($NextID);
        my $HasApproval=_HasApproval($Next,{});
        return if !defined $HasApproval || $HasApproval;
    }
    my $Iteration=_Scalar($T->{'DynamicField_ZIN-Iteration'});
    my %Levels=map {$_->{BlueLevel}=>1} grep {$_->{Type} eq 'Approval'} @{$Rows};
    for my $Level (keys %Levels) {
        return if !Kernel::System::ZTSMBlueBookRuntime::LevelComplete(ParentTicketID=>$T->{TicketID},BlueBookID=>$BookID,BlueLevel=>$Level,Iteration=>$Iteration,UserID=>1);
    }
    my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my %Search=(UserID=>1,'DynamicField_ZTicket-Parent'=>{Equals=>$T->{TicketID}});
    $Search{'DynamicField_ZIN-Iteration'}={Equals=>$Iteration} if defined $Iteration && $Iteration ne '';
    my $Count=$Ticket->TicketSearch(%Search,Result=>'COUNT',Limit=>1);
    return if !$Count || $Count !~ /\A\d+\z/;
    my @IDs=$Ticket->TicketSearch(%Search,Result=>'ARRAY',Limit=>$Count);
    my (%Outcomes,@Evidence);
    for my $ID (@IDs) {
        my %C=$Ticket->TicketGet(TicketID=>$ID,DynamicFields=>1,UserID=>1);
        my $ChildIteration=_Scalar($C{'DynamicField_ZIN-Iteration'});
        next if (defined $Iteration?$Iteration:'') ne (defined $ChildIteration?$ChildIteration:'');
        next if (_Scalar($C{'DynamicField_ZTicket-Parent'})||'') ne $T->{TicketID};
        next if ($C{StateType}||'') ne 'closed' || ($C{State}||'') ne 'closed successful';
        # Native success is 0. Older successful child submissions may omit the
        # outcome field; the fulfilled closure and governed level still prove completion.
        my $ExecutionOutcome=_Scalar($C{'DynamicField_ZTicket-Outcome'});
        next if defined $ExecutionOutcome && $ExecutionOutcome ne '' && $ExecutionOutcome ne '0';
        if (($C{Type}||'') eq 'Assessment') {
            my $Outcome=_Scalar($C{'DynamicField_RiskAssessmentOutcome'});
            $Outcomes{$Outcome}=1 if defined $Outcome && $Outcome ne '';
        }
        if (($C{Type}||'') eq 'Approval' && (_Scalar($C{'DynamicField_ZTicket-BlueBook'})||'') eq $BookID) {
            my @H=$Ticket->HistoryGet(TicketID=>$ID,UserID=>1);
            my @Closed=grep {($_->{HistoryType}||'') eq 'StateUpdate' && ($_->{Name}||'') =~ /\A%%[^%]*%%closed successful%%\z/} @H;
            return if !@Closed;
            push @Evidence,"$ID:".$Closed[-1]{CreateTime};
        }
    }
    return if keys(%Outcomes)!=1 || !@Evidence;
    my ($Outcome)=keys %Outcomes;
    my @Dates=sort map {s/^\d+://r} @Evidence;
    my $Date=$Dates[-1];
    return if !defined Kernel::System::TESSERA::RiskRegister::Epoch($Date);
    my $Marker='ZTSM Risk Governance Decision '.sha256_hex(join('|',$T->{TicketID},$BookID,$Iteration||'',sort @Evidence));
    return {Outcome=>$Outcome,GovernanceDate=>$Date,Marker=>$Marker};
}
sub Read {
    my ($Self,%P)=@_;
    my $T=$P{Ticket}||{};
    return if ($T->{Type}||'') ne 'ServiceRequest' || _Scalar($T->{'DynamicField_ZTicket-Parent'});
    my $ID=_Scalar($T->{'DynamicField_ZTicket-StateBook'});return if !$ID;
    my $Book=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>1,UserID=>1);
    return if ref $Book ne 'HASH';
    my @Records=Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume::_RecordsParse(StateBook=>$Book);
    my @Decisions;
    for my $Index (0..$#Records) {
        my $Decision=$Self->Evidence(Ticket=>$T,Records=>\@Records,CurrentIndex=>$Index);
        push @Decisions,$Decision if $Decision;
    }
    return if @Decisions != 1;
    my $Field=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>'RiskAssessmentOutcome');
    return if ref $Field ne 'HASH' || !exists $Field->{Config}{PossibleValues}{$Decisions[0]{Outcome}};
    return $Decisions[0];
}
sub Run {
    my ($Self,%P)=@_;
    my $T=$P{Ticket}||{};
    my $Decision=$Self->Evidence(%P);
    return 1 if !$Decision;
    my $Outcome=$Decision->{Outcome};
    my $Date=$Decision->{GovernanceDate};
    my $Marker=$Decision->{Marker};
    my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');
    my $OutcomeField=$DF->DynamicFieldGet(Name=>'RiskAssessmentOutcome');
    my $DateField=$DF->DynamicFieldGet(Name=>'ITSMDecisionDate');
    return if ref $OutcomeField ne 'HASH' || ($OutcomeField->{ObjectType}||'') ne 'Ticket' || !exists $OutcomeField->{Config}{PossibleValues}{$Outcome} || ref $DateField ne 'HASH' || ($DateField->{ObjectType}||'') ne 'Ticket' || ($DateField->{FieldType}||'') ne 'DateTime';
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Lock='TESSERA.RiskDecision.'.$T->{TicketID};
    return if !$PID->PIDCreate(Name=>$Lock);
    my $Success=eval {
        my @H=$Ticket->HistoryGet(TicketID=>$T->{TicketID},UserID=>1);
        if (!grep {($_->{Name}||'') eq $Marker} @H) {
            # Completion evidence is stable on replay and changes for a renewed
            # governed approval. It does not use assessment submission time.
            my $Backend=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
            die "Cannot save master Risk Outcome\n" if !$Backend->ValueSet(DynamicFieldConfig=>$OutcomeField,ObjectID=>$T->{TicketID},Value=>$Outcome,UserID=>1);
            die "Cannot save master governance date\n" if !$Backend->ValueSet(DynamicFieldConfig=>$DateField,ObjectID=>$T->{TicketID},Value=>$Date,UserID=>1);
            die "Cannot record risk governance evidence\n" if !$Ticket->HistoryAdd(TicketID=>$T->{TicketID},HistoryType=>'Misc',Name=>$Marker,CreateUserID=>1);
        }
        1;
    };
    my $Error=$@;
    $PID->PIDDelete(Name=>$Lock);
    $Kernel::OM->Get('Kernel::System::Log')->Log(Priority=>'error',Message=>"Risk governance decision failed: $Error") if $Error;
    return $Success;
}
1;
