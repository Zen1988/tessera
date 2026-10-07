use strict; use warnings; use Test::More; use FindBin qw($Bin);
open my $F, '<', "$Bin/../../../Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketZoom.pm" or die $!;
my $Source = do {local $/; <$F>};
my ($Function) = $Source =~ /(sub _ZTSMRiskPlanValues \{.*?)(?=sub _ZTSMVerificationCompletionHTML)/s;
die 'Missing helper' unless $Function;
sub _ZTSMNormalizeValue { my ($V)=@_; return ref $V eq 'ARRAY' ? $V->[0] : $V; }
eval $Function; die $@ if $@;
is_deeply([_ZTSMRiskPlanValues('Replace unsupported product')], ['Replace unsupported product'], 'normal text plan is not discarded');
is_deeply([_ZTSMRiskPlanValues(['First','Second'])], ['First','Second'], 'all multiple plan values retained');
is_deeply([_ZTSMRiskPlanValues([{ 'ZRM-RiskPlan'=>'Grouped plan' }])], ['Grouped plan'], 'grouped plan retained');
is_deeply([_ZTSMRiskPlanValues(undef)], [], 'missing value stays absent');
is_deeply([_ZTSMRiskPlanValues('')], [''], 'empty text left for caller filtering');

{
    package PlanOM;
    sub new { bless {}, shift }
    sub Get { $_[0] }
    sub TicketSearch { my ($S,%P)=@_; main::is_deeply($P{'DynamicField_ZTicket-Parent'}, {Equals=>325}, 'lookup stays within execution parent'); return (326,900); }
    sub TicketGet { my ($S,%P)=@_; return (TicketID=>$P{TicketID}, State=>'closed successful', 'DynamicField_ZTicket-Parent'=>$P{TicketID}==326?325:999); }
    sub MELTObjectGet { return { Class=>'Risk', 'DynamicField_MELT-RiskStmt'=>630 }; }
    sub DynamicFieldGet { my ($S,%P)=@_; return {Name=>$P{Name},ObjectType=>'Ticket',FieldType=>'RichText',Config=>{DefaultValue=>['<p>Step:</p>']}}; }
    sub RichText2Ascii { my ($S,%P)=@_; return $P{String} =~ s/<[^>]+>//gr; }
    sub EditFieldRender { my ($S,%P)=@_; main::is($P{DynamicFieldConfig}->{FieldType},'TextArea','RichText uses local plain driver'); main::is_deeply($P{Value}, ['Step:'], 'array-valued rich default converted before driver rendering'); return {Field=>'<textarea>Step:</textarea>',Label=>'<label>Result</label>'}; }
    sub ValueGet { return [{'ZRM-RiskStatement'=>630,'ZRM-RiskPlan'=>'Retained plan'}]; }
    sub Ascii2Html { my ($S,%P)=@_; return $P{Text}; }
}
sub IsHashRefWithData { ref $_[0] eq 'HASH' && keys %{$_[0]} }
{
    no warnings 'once';
    $Kernel::OM = PlanOM->new;
}
my ($Render) = $Source =~ /(sub _ZTSMRiskTreatmentHTML \{.*?)(?=sub _ZTSMRiskPlanValues)/s;
eval $Render; die $@ if $@;
my $HTML = _ZTSMRiskTreatmentHTML({}, Ticket=>{'DynamicField_ZTicket-Parent'=>325,'DynamicField_ZRM-OriginatedEvent'=>21});
like($HTML,qr/Retained plan/,'plan rendered without duplicated origin field on Assessment');
unlike($HTML,qr/No risk plan/,'populated plan does not show missing message');

my ($Fields) = $Source =~ /(sub _ZTSMRuntimeRiskFieldsHTML \{.*?)(?=sub _GetNextStates)/s;
eval $Fields; die $@ if $@;
sub IsArrayRefWithData { ref $_[0] eq 'ARRAY' && @{$_[0]} }
my $Form = _ZTSMRuntimeRiskFieldsHTML({},Ticket=>{TicketID=>328},Fields=>['ZTicket-Result']);
like($Form,qr/<textarea>Step:<\/textarea>/,'plain default reaches textarea');
unlike($HTML,qr/RiskPlanAcknowledged/,'plan context has no acknowledgement requirement');
like($Source,qr/Name => 'ZTSMRuntimeActionDialog',\s*Data => \{\s*%\{\$RuntimeAction\},\s*TicketID => \$Param\{TicketID\},\s*FormID\s*=> \$Self->\{FormID\}/,'runtime dialog receives prepared FormID for search and submit');
open my $TF,'<',"$Bin/../../../Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt" or die $!;
my $Template=do{local $/;<$TF>};
my ($RuntimeForm)=$Template =~ /(<form[^>]*name="ZTSMRuntimeAction\[% Data.Action.*?<\/form>)/s;
like($RuntimeForm,qr/name="FormID" value="\[% Data.FormID \| html %\]"/,'actual runtime form contains bound FormID, not another form block');
done_testing;
