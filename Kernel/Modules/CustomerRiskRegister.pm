package Kernel::Modules::CustomerRiskRegister;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($Type,%P)=@_;return bless {%P},$Type}
sub Run {
    my ($Self,%P)=@_;
    my $Layout=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    return $Layout->CustomerNoPermission(WithHeader=>'yes') if !$Self->{UserID};
    my $Mode=$Kernel::OM->Get('Kernel::System::Web::Request')->GetParam(Param=>'View')||'Current';
    $Mode='Current' if $Mode ne 'Review';
    my $Report=eval {$Kernel::OM->Get('Kernel::System::TESSERA::RiskRegister')->Report(CustomerUserID=>$Self->{UserID})};
    if (!$Report) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(Priority=>'error',Message=>"Risk Register mapping: $@");
        return $Layout->CustomerErrorScreen(Message=>'Risk Register mapping could not be resolved. Ask your administrator to check TESSERA::RiskRegister::Columns.');
    }
    my $Request=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $Presentation=($Request->GetParam(Param=>'Display')||'') eq 'List'?'List':'Dashboard';
    my $Entries=$Report->{Rows};
    my $Search=$Request->GetParam(Param=>'RiskSearch')||'';
    my @Rows=grep {$_->{Status} eq $Mode} @{$Entries};
    @Rows=grep {index(lc(join(' ', $_->{TicketNumber}||'', @{$_->{Cells}||[]})),lc($Search))>=0} @Rows if $Presentation eq 'List' && $Search ne '';
    if (($Kernel::OM->Get('Kernel::System::Web::Request')->GetParam(Param=>'Subaction')||'') eq 'Export') {
        @Rows=@{$Entries} if $Presentation eq 'Dashboard';
        my $Excel=$Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ExportSheets(Sheets=>[{
            Name=>'Risk Register',Head=>[map {$_->{Label}} @{$Report->{Columns}}],Data=>[map {$_->{Cells}} @Rows],
        }]);
        return $Layout->Attachment(Filename=>'risk_register.xlsx',ContentType=>'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',Content=>$Excel);
    }
    my $Dashboard=$Kernel::OM->Get('Kernel::System::TESSERA::RiskRegister')->DashboardComparison(Rows=>$Report->{Rows},CategoryField=>$Request->GetParam(Param=>'CategoryField'),CategoryID=>$Request->GetParam(Param=>'CategoryID'));
    my $Current=scalar grep {$_->{Status} eq 'Current'} @{$Entries};
    my $Review=scalar grep {$_->{Status} eq 'Review'} @{$Entries};
    my $Output=$Layout->CustomerHeader(Title=>'Risk Register');
    $Output.=$Layout->CustomerNavigationBar();
    $Output.=$Layout->Output(TemplateFile=>'CustomerRiskRegister',Data=>{Rows=>\@Rows,Columns=>$Report->{Columns},View=>$Mode,CurrentCount=>$Current,ReviewCount=>$Review,Display=>$Presentation,Dashboard=>$Dashboard,RiskSearch=>$Search});
    $Output.=$Layout->CustomerFooter();
    return $Output;
}
1;
