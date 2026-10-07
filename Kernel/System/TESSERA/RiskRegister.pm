package Kernel::System::TESSERA::RiskRegister;
use strict;
use warnings;
use DateTime;
our @ObjectDependencies = qw(Kernel::System::Ticket Kernel::System::Service Kernel::System::State Kernel::System::DynamicField Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck Kernel::Config Kernel::System::YAML Kernel::System::DynamicField::Backend Kernel::System::GeneralCatalog Kernel::System::GovernanceObject Kernel::System::ITSMConfigItem Kernel::System::TESSERA::RiskGovernanceDecision);
sub new { return bless {}, $_[0] }
sub ScalarValue {
    my ($Value) = @_;
    return if !defined $Value;
    return ScalarValue($Value->[0]) if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value;
    return $Value;
}
sub Epoch {
    my ($String) = @_;
    return if !defined $String || $String !~ /\A(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\z/;
    my @Parts = ($1,$2,$3,$4,$5,$6);
    my $Date = eval { DateTime->new(year=>$Parts[0],month=>$Parts[1],day=>$Parts[2],hour=>$Parts[3],minute=>$Parts[4],second=>$Parts[5],time_zone=>'UTC') };
    return $Date ? $Date->epoch : undef;
}
sub Evaluate {
    my ($Self,%P) = @_;
    my $T = $P{Ticket} || {};
    return { Status=>'Excluded' } if ($T->{Service}||'') ne 'Risk::Management' || ($T->{Type}||'') ne 'ServiceRequest' || ScalarValue($T->{'DynamicField_ZTicket-Parent'});
    my $Outcome = ScalarValue($T->{'DynamicField_RiskAssessmentOutcome'}) || '';
    my $Accepted = $P{AcceptedValue} && $Outcome eq $P{AcceptedValue};
    # Only the final, Book-governed approval writer creates this master marker.
    # Assessment completion or a state change into an approval stage is not approval.
    my $Approved = grep {
        ($_->{HistoryType}||'') eq 'Misc'
            && ($_->{Name}||'') =~ /\AZTSM Risk Governance Decision [a-f0-9]{64}\z/
    } @{$P{History}||[]};
    # Read-only recovery for approvals whose capture was skipped by older builds.
    # The reader validates the actual final Books, successful children and iteration.
    my $Decision=ref $P{Decision} eq 'HASH' ? $P{Decision} : {};
    if (!$Approved && ($Decision->{Marker}||'') =~ /\AZTSM Risk Governance Decision [a-f0-9]{64}\z/) {
        $Approved=1;
        $Outcome=$Decision->{Outcome}||'';
        $Accepted=$P{AcceptedValue} && $Outcome eq $P{AcceptedValue};
    }
    return {Status=>'Excluded'} if !$Approved || $Outcome eq '';
    my $Active = ($T->{StateType}||'') ne '' && $T->{StateType} ne 'closed';
    return {Status=>'Excluded'} if !$Accepted && !$Active;
    my $Date = $Decision->{GovernanceDate} || ScalarValue($T->{'DynamicField_ITSMDecisionDate'});
    my $Start = Epoch($Date);
    my $Now = defined $P{Now} ? $P{Now} : time;
    return {Status=>'Review',Reason=>'Governance date missing or invalid',Outcome=>$Outcome} if !defined $Start || $Start > $Now;
    # Maximum 365 elapsed days; the exact anniversary is already due for review.
    my $Due = $Start + 365 * 86400;
    my $DueDate = DateTime->from_epoch(epoch=>$Due,time_zone=>'UTC')->strftime('%Y-%m-%d %H:%M:%S');
    return {Status=>$Now >= $Due ? 'Review' : 'Current',Reason=>$Now >= $Due ? 'Annual review required' : ($Accepted ? 'Accepted risk' : 'Active risk'),Outcome=>$Outcome,GovernanceDate=>$Date,ReviewDue=>$DueDate};
}
sub Visible {
    my ($Self,%P)=@_;
    return if !$P{CustomerUserID} || !$P{TicketID};
    my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my %Data=$Ticket->TicketGet(TicketID=>$P{TicketID},UserID=>1,DynamicFields=>0);
    # Native read is sufficient for the requester, not company/queue membership.
    return 1 if lc($Data{CustomerUserID}||'') eq lc($P{CustomerUserID})
        && $Ticket->TicketCustomerPermission(Type=>'ro',TicketID=>$P{TicketID},UserID=>$P{CustomerUserID});
    return $Kernel::OM->Get('Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck')->Run(Type=>'ro',TicketID=>$P{TicketID},CustomerUserID=>$P{CustomerUserID});
}
sub Columns {
    my ($Self) = @_;
    my $Columns = $Kernel::OM->Get('Kernel::Config')->Get('TESSERA::RiskRegister::Columns');
    if (defined $Columns && !ref $Columns) {
        $Columns=$Kernel::OM->Get('Kernel::System::YAML')->Load(Data=>$Columns);
    }
    die "Risk Register column mapping is missing" if ref $Columns ne 'ARRAY' || !@{$Columns};
    my %Metadata = map {$_=>1} qw(TicketNumber Title State CreateTime Outcome GovernanceDate ReviewDue Reason);
    for my $Column (@{$Columns}) {
        die "Invalid Risk Register column mapping" if ref $Column ne 'HASH'
            || !$Column->{Label} || ($Column->{Source}||'') !~ /\A(?:Row|Assessment|Master|TargetGO)\z/ || !$Column->{Field};
        if ($Column->{Source} =~ /\ATargetGO\z/) {
            my $Via=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$Column->{Via}||'');
            my $Expected=$Column->{Source} eq 'TargetGO' ? 'GovernanceObject' : 'ConfigItem';
            die "Invalid target reference mapping" if !$Via || ($Via->{FieldType}||'') ne $Expected;
        }
        next if $Column->{Source} =~ /\A(?:Assessment|Master)\z/ && $Metadata{$Column->{Field}};
        my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$Column->{Field});
        die "Unknown Risk Register field: $Column->{Field}" if ref $Field ne 'HASH' || !$Field->{ID};
        die "Unsupported Risk Register field: $Column->{Field}" if ($Field->{FieldType}||'') =~ /\A(?:Set|Group)\z/;
    }
    return $Columns;
}
sub DisplayValue {
    my ($Self,%P)=@_;
    my $Value=$Self->_DisplayValue(%P);
    return $P{ValueMap}{$Value} if ref $P{ValueMap} eq 'HASH' && exists $P{ValueMap}{$Value};
    return $Value;
}
sub _DisplayValue {
    my ($Self,%P)=@_;
    my $Value=$P{Value};
    return '' if !defined $Value;
    return join ', ',map {$Self->DisplayValue(%P,Value=>$_)} @{$Value} if ref $Value eq 'ARRAY';
    die "Structured value requires a scalar field mapping" if ref $Value;
    return "$Value" if $P{Metadata};
    my $Field=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$P{Field});
    my $Type=$Field->{FieldType}||'';
    return $Field->{Config}{PossibleValues}{$Value} // "$Value" if $Type eq 'Dropdown';
    if ($Type eq 'GeneralCatalog') {
        my $Item=$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(ItemID=>$Value);
        die "Unresolved catalog value for $P{Field}" if !$Item || !defined $Item->{Name};
        return $Item->{Name};
    }
    if ($Type eq 'GovernanceObject' || $Type eq 'ConfigItem') {
        my $Object=$Type eq 'GovernanceObject'
            ? $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$Value,Silent=>1)
            : $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(ConfigItemID=>$Value,Silent=>1);
        die "Unresolved reference for $P{Field}" if !$Object || !defined $Object->{Name};
        return $Object->{Name};
    }
    return "$Value";
}
sub _ScoreColorObject {
    my ($Self,$ID)=@_;
    my $Cache=$Self->{ScoreColorObjects};
    return $Cache->{$ID} if ref $Cache eq 'HASH' && exists $Cache->{$ID};
    my $Object=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID=>$ID,DynamicFields=>1,Silent=>1,
    );
    $Cache->{$ID}=$Object if ref $Cache eq 'HASH';
    return $Object;
}
sub ScoreDecoration {
    my ($Self,%P)=@_;
    my $ID=ScalarValue($P{Row}->{'ZRM-Framework'});
    my $Score=ScalarValue($P{Score});
    return {} if !$ID || $ID !~ /\A\d+\z/ || !defined $Score || $Score !~ /\A\d+(?:\.\d+)?\z/;
    my $Framework=$Self->_ScoreColorObject($ID);
    return {} if ref $Framework ne 'HASH' || ($Framework->{Class}||'') ne 'Framework';
    my $Matrix=$Framework->{'DynamicField_RiskMatrix'};
    return {} if ref $Matrix ne 'ARRAY';
    my @Matches;
    for my $Band (@{$Matrix}) {
        return {} if ref $Band ne 'HASH';
        my $Start=ScalarValue($Band->{'ZRM-StartScore'});
        my $End=ScalarValue($Band->{'ZRM-EndScore'});
        return {} if !defined $Start || !defined $End || $Start !~ /\A\d+(?:\.\d+)?\z/
            || $End !~ /\A\d+(?:\.\d+)?\z/ || $Start>$End;
        push @Matches,$Band if $Score >= $Start && $Score <= $End;
    }
    return {} if @Matches != 1;
    my $SeverityID=ScalarValue($Matches[0]->{'ZRM-RiskSeverity'});
    return {} if !$SeverityID || $SeverityID !~ /\A\d+\z/;
    my $Severity=$Self->_ScoreColorObject($SeverityID);
    return {} if ref $Severity ne 'HASH' || ($Severity->{Class}||'') ne 'EventSeverity' || !$Severity->{Name};
    my $Color=ScalarValue($Severity->{'DynamicField_ZTSM-ColorHex'});
    return {} if !defined $Color || $Color !~ /\A#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})\z/;
    my $Hex=$1;
    $Hex=join '',map {$_.$_} split //,$Hex if length($Hex)==3;
    my @RGB=map {hex($_)/255} ($Hex =~ /(..)/g);
    my @Linear=map {$_<=0.04045 ? $_/12.92 : (($_+0.055)/1.055)**2.4} @RGB;
    my $L=0.2126*$Linear[0]+0.7152*$Linear[1]+0.0722*$Linear[2];
    my $Foreground=($L+0.05)/0.05 >= 1.05/($L+0.05) ? '#000000' : '#ffffff';
    return {Color=>'#'.lc($Hex),Foreground=>$Foreground,Label=>$Severity->{Name},
        Title=>($Framework->{Name}||'Framework').' / '.$Severity->{Name}.' (current Framework matrix)'};
}
sub Report {
    my ($Self,%P)=@_;
    local $Self->{ScoreColorObjects}={};
    my $Columns=$Self->Columns();
    my $Entries=$Self->Entries(%P);
    my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my $Set=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>'ZRM-RiskAssessment');
    die "Risk Assessment field is unavailable" if !$Set || !$Set->{ID};
    my @Rows;
    for my $Master (@{$Entries}) {
        my %M=$Ticket->TicketGet(TicketID=>$Master->{TicketID},DynamicFields=>1,UserID=>1);
        my %Search=(Types=>['Assessment'],UserID=>1,'DynamicField_ZTicket-Parent'=>{Equals=>$Master->{TicketID}});
        my $Count=$Ticket->TicketSearch(%Search,Result=>'COUNT',Limit=>1)||0;
        next if !$Count;
        my @IDs=$Ticket->TicketSearch(%Search,Result=>'ARRAY',Limit=>$Count);
        my @Assessments;
        for my $ID (@IDs) {
            next if !$Self->Visible(TicketID=>$ID,CustomerUserID=>$P{CustomerUserID});
            my %A=$Ticket->TicketGet(TicketID=>$ID,DynamicFields=>1,UserID=>1);
            next if ($A{Type}||'') ne 'Assessment' || (ScalarValue($A{'DynamicField_ZTicket-Parent'})||'') ne $Master->{TicketID};
            next if (ScalarValue($A{'DynamicField_ZIN-Iteration'})//'') ne (ScalarValue($M{'DynamicField_ZIN-Iteration'})//'');
            next if ($A{StateType}||'') ne 'closed' || ($A{State}||'') ne 'closed successful';
            push @Assessments,\%A;
        }
        # Latest submitted Assessment in this execution iteration; older submissions remain audit evidence.
        @Assessments=sort {($b->{Created}||$b->{CreateTime}||'') cmp ($a->{Created}||$a->{CreateTime}||'') || $b->{TicketID}<=>$a->{TicketID}} @Assessments;
        next if !@Assessments;
        my $A=$Assessments[0];
        my $Values=$Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueGet(DynamicFieldConfig=>$Set,ObjectID=>$A->{TicketID});
        next if ref $Values ne 'ARRAY';
        my $Index=0;
        for my $Row (@{$Values}) {
            next if ref $Row ne 'HASH';
            $Index++;
            my @Cells;
            my @Decorations;
            for my $C (@{$Columns}) {
                push @Decorations,($C->{Source} eq 'Row' && $C->{Field} =~ /\AZRM-(?:Inherent|Residual)CalculatedRisk\z/)
                    ? $Self->ScoreDecoration(Row=>$Row,Score=>$Row->{$C->{Field}}) : {};
                if ($C->{Source} =~ /\ATargetGO\z/) {
                    my $References=$Row->{$C->{Via}};
                    my @IDs=ref $References eq 'ARRAY' ? @{$References} : defined $References ? ($References) : ();
                    my @Values;
                    for my $ID (@IDs) {
                        my $Object=$C->{Source} eq 'TargetGO'
                            ? $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>1,Silent=>1)
                            : $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>1,Silent=>1);
                        die "Mapped target could not be resolved" if !$Object;
                        my $Value=$Object->{'DynamicField_'.$C->{Field}};
                        $Value=$Object->{XMLData}{$C->{Field}} if !defined $Value && ref $Object->{XMLData} eq 'HASH';
                        push @Values,$Self->DisplayValue(Field=>$C->{Field},Value=>$Value,ValueMap=>$C->{ValueMap});
                    }
                    push @Cells,join ', ',@Values;
                    next;
                }
                my $Source=$C->{Source} eq 'Row' ? $Row : $C->{Source} eq 'Assessment' ? $A : {%M,%{$Master}};
                my $Metadata=$C->{Source} ne 'Row' && exists $Source->{$C->{Field}};
                my $Value=$Source->{$C->{Source} eq 'Row' || $Metadata ? $C->{Field} : 'DynamicField_'.$C->{Field}};
                push @Cells,$Self->DisplayValue(Field=>$C->{Field},Value=>$Value,Metadata=>$Metadata,ValueMap=>$C->{ValueMap});
            }
            push @Rows,{%{$Master},TicketID=>$A->{TicketID},TicketNumber=>$A->{TicketNumber},Title=>$A->{Title},RowNumber=>$Index,RiskRow=>$Row,AssessmentCreated=>($A->{Created}||$A->{CreateTime}),MasterOpen=>(($M{StateType}||'') ne 'closed'?1:0),Cells=>\@Cells,Decorations=>\@Decorations};
        }
    }
    return {Columns=>$Columns,Rows=>\@Rows};
}
# Dashboard consumes only the report's permission-filtered assessment rows.
# Both score bases share the same permission-filtered rows and summary counts.
sub DashboardComparison {
    my ($Self,%P)=@_;
    my @Bases=map {$Self->Dashboard(%P,Measure=>$_)} ('Inherent','Residual');
    return {(map {$_=>$Bases[0]{$_}} qw(Open Upcoming New)), Bases=>\@Bases};
}

sub Dashboard {
    my ($Self,%P)=@_; local $Self->{ScoreColorObjects}={};
    my $Now=defined $P{Now}?$P{Now}:time;
    my $Today=DateTime->from_epoch(epoch=>$Now,time_zone=>'UTC');
    my $Since=$Today->clone->subtract(months=>1)->epoch;
    my $Until=$Today->clone->add(months=>1)->epoch;
    my (%Groups,%Frameworks); my ($Open,$Upcoming,$New)=(0,0,0);
    my $Measure=($P{Measure}||'') eq 'Residual'?'Residual':'Inherent';
    for my $Entry (@{$P{Rows}||[]}) {
        my $Row=$Entry->{RiskRow}||{};
        $Open++ if $Entry->{MasterOpen};
        my $Due=Epoch($Entry->{ReviewDue});
        $Upcoming++ if $Entry->{Status} eq 'Review' || (defined $Due && $Due <= $Until);
        my $Created=Epoch($Entry->{AssessmentCreated});
        $New++ if defined $Created && $Created >= $Since && $Created <= $Now;
        my $Decoration=$Self->ScoreDecoration(Row=>$Row,Score=>$Row->{'ZRM-'.$Measure.'CalculatedRisk'});
        my $Severity=$Decoration->{Label}||'Unmapped';
        for my $Field ('ZRM-ImpactCategory','ZRM-RiskCategory') {
            my $Values=$Row->{$Field}; my @Values=ref $Values eq 'ARRAY'?@{$Values}:defined $Values?($Values):();
            @Values=('') if !@Values; my %Seen;
            for my $ID (@Values) {
                next if !defined $ID || ref $ID || $Seen{$ID}++;
                my $Group=$Groups{$Field}{$ID} ||= {ID=>$ID,Field=>$Field,Label=>($ID ne ''?$Self->DisplayValue(Field=>$Field,Value=>$ID):'Unspecified'),Count=>0,Severity=>{}};
                $Group->{Count}++;
                my $Band=$Group->{Severity}{$Severity} ||= {Label=>$Severity,Color=>$Decoration->{Color}||'#e4e6ef',Foreground=>$Decoration->{Foreground}||'#000539',Count=>0};
                $Band->{Count}++;
            }
        }
        next if !$P{CategoryField} || $P{CategoryField} !~ /\AZRM-(?:ImpactCategory|RiskCategory)\z/;
        my $V=$Row->{$P{CategoryField}};my @V=ref $V eq 'ARRAY'?@{$V}:defined $V?($V):('');
        next if !grep {defined $_ && !ref $_ && $_ eq ($P{CategoryID}//'')} @V;
        my $FID=ScalarValue($Row->{'ZRM-Framework'});next if !$FID || $FID!~/\A\d+\z/;
        my $F=$Self->_ScoreColorObject($FID);next if ref $F ne 'HASH'||($F->{Class}||'') ne 'Framework';
        my $L=ScalarValue($F->{'DynamicField_ZRM-LikelihoodScale'});my $I=ScalarValue($F->{'DynamicField_ZRM-ImpactScale'});
        next if !defined $L || !defined $I || $L!~/\A[1-9]\d*\z/ || $I!~/\A[1-9]\d*\z/ || $L*$I>10000;
        my $Matrix=$Frameworks{$FID} ||= {Name=>$F->{Name},ID=>$FID,L=>$L,I=>$I,Entries=>{},Unplaced=>[]};
        my $LV=$Self->DisplayValue(Field=>'ZRM-'.$Measure.'Likelihood',Value=>$Row->{'ZRM-'.$Measure.'Likelihood'});
        my $IV=$Self->DisplayValue(Field=>'ZRM-'.$Measure.'Impact',Value=>$Row->{'ZRM-'.$Measure.'Impact'});
        if ($LV!~/\A[1-9]\d*\z/||$IV!~/\A[1-9]\d*\z/||$LV>$L||$IV>$I) {push @{$Matrix->{Unplaced}},$Entry;next;}
        push @{$Matrix->{Entries}{"$LV:$IV"}},$Entry;
    }
    my @Charts;
    for my $Field ('ZRM-ImpactCategory','ZRM-RiskCategory') {
        my @G=sort {$b->{Count}<=>$a->{Count}||$a->{Label} cmp $b->{Label}} values %{$Groups{$Field}||{}};
        my $Max=@G?$G[0]{Count}:1;
        for my $G (@G) {$G->{Width}=100*$G->{Count}/$Max;$G->{Bands}=[map {{%$_,Width=>100*$_->{Count}/$G->{Count}}} sort {$a->{Label} cmp $b->{Label}} values %{$G->{Severity}}];}
        push @Charts,{Title=>$Field eq 'ZRM-ImpactCategory'?'Category':'Risk Category',Groups=>\@G};
    }
    my @Matrices;
    for my $M (sort {$a->{Name} cmp $b->{Name}} values %Frameworks) {
        $M->{Impacts}=[1..$M->{I}];my @Lines;
        for my $L (reverse 1..$M->{L}) {my @Cells;
            for my $I (1..$M->{I}) {my $D=$Self->ScoreDecoration(Row=>{'ZRM-Framework'=>$M->{ID}},Score=>$L*$I);
                my $Entries=$M->{Entries}{"$L:$I"}||[];
                push @Cells,{%{$D},Likelihood=>$L,Impact=>$I,Count=>scalar @{$Entries},Entries=>$Entries};}
            push @Lines,{Likelihood=>$L,Cells=>\@Cells};}
        $M->{Lines}=\@Lines;push @Matrices,$M;
    }
    return {Open=>$Open,Upcoming=>$Upcoming,New=>$New,Charts=>\@Charts,Matrices=>\@Matrices,Measure=>$Measure};
}
sub Entries {
    my ($Self,%P)=@_;
    return [] if !$P{CustomerUserID};
    my %Services = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(Valid=>1,UserID=>1);
    my @Services = grep {$Services{$_} eq 'Risk::Management'} keys %Services;
    return [] if @Services != 1;
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>'RiskAssessmentOutcome');
    my $Values = ref $Field eq 'HASH' ? $Field->{Config}{PossibleValues} : {};
    my @Accepted = ref $Values eq 'HASH' ? grep {($_ eq 'Risk Accepted' || $Values->{$_} eq 'Risk Accepted')} keys %{$Values} : ();
    my $Ticket = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Search = (ServiceIDs=>\@Services,Types=>['ServiceRequest'],UserID=>1);
    my $Count = $Ticket->TicketSearch(%Search,Result=>'COUNT',Limit=>1);
    return [] if !$Count || $Count !~ /\A\d+\z/;
    my @IDs = $Ticket->TicketSearch(%Search,Result=>'ARRAY',Limit=>$Count);
    my @Rows;
    for my $ID (@IDs) {
        next if !$Self->Visible(TicketID=>$ID,CustomerUserID=>$P{CustomerUserID});
        my %T = $Ticket->TicketGet(TicketID=>$ID,DynamicFields=>1,UserID=>1);
        next if !%T || ScalarValue($T{'DynamicField_ZTicket-Parent'});
        $T{Service}=$Services{$T{ServiceID}}||'';
        my @History=$Ticket->HistoryGet(TicketID=>$ID,UserID=>1);
        my $Decision;
        if (!grep {($_->{HistoryType}||'') eq 'Misc' && ($_->{Name}||'') =~ /\AZTSM Risk Governance Decision [a-f0-9]{64}\z/} @History) {
            $Decision=$Kernel::OM->Get('Kernel::System::TESSERA::RiskGovernanceDecision')->Read(Ticket=>\%T);
        }
        my $Result=$Self->Evaluate(Ticket=>\%T,History=>\@History,Decision=>$Decision,AcceptedValue=>@Accepted==1?$Accepted[0]:undef,Now=>$P{Now});
        next if $Result->{Status} eq 'Excluded';
        push @Rows,{%{$Result},TicketID=>$ID,TicketNumber=>$T{TicketNumber},Title=>$T{Title},State=>$T{State}};
    }
    return [sort {($a->{ReviewDue}||'') cmp ($b->{ReviewDue}||'') || $a->{TicketID}<=>$b->{TicketID}} @Rows];
}
1;
