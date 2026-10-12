package Kernel::Modules::CustomerSecurityAdvisory;
use strict;use warnings;use Digest::SHA qw(sha256_hex);
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless {%P},$T}
sub Run {
 my ($Self)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
 return $L->CustomerNoPermission(WithHeader=>'yes') if !$Self->{UserID};
 my $R=$Kernel::OM->Get('Kernel::System::Web::Request');my $S=$Kernel::OM->Get('Kernel::System::TESSERA::SecurityAdvisory');
 return $L->CustomerNoPermission(WithHeader=>'yes') if !$S->AccessCheck(CustomerUserID=>$Self->{UserID});
 my $M=eval{$S->Model(CustomerUserID=>$Self->{UserID})};
 return $L->CustomerErrorScreen(Message=>'Security advisory model is unavailable. Please contact your administrator.') if !$M;
 my $Sub=$R->GetParam(Param=>'Subaction')||'';my (@Results,$Error);
 $Sub='Export' if $Sub eq 'Save' && $R->GetParam(Param=>'ExportForm');
 my $Overview=eval {$S->Overview(CustomerUserID=>$Self->{UserID},Model=>$M)};
 return $L->CustomerErrorScreen(Message=>'Security advisory overview is unavailable. Please contact your administrator.') if !$Overview;
 my $View=($R->GetParam(Param=>'AdvisoryView')||'') eq 'List' ? 'List' : 'Dashboard';
 if ($Sub eq 'ExportList') {
  my @Headers=('Class','Name','Description',map {$_->{Name}} @{$Overview->{Columns}});
  my @Rows=map {my $Row=$_;my @Cells=@{$Row->{Cells}};
   for my $I (0..$#{$Overview->{Columns}}) {my $Name=$Overview->{Columns}[$I]{Name};
    if ($Name eq 'AdvancedCondition') {$Cells[$I]=$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$Row->{Object}{'DynamicField_AdvancedCondition'}||[]);}}
   ['SecurityAdvisory',$Row->{Object}{Name}//'',$Row->{Object}{Description}//'',@Cells]} @{$Overview->{Rows}};
  my $X=$Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ExportSheets(Sheets=>[{Name=>'SecurityAdvisory',Head=>\@Headers,Data=>\@Rows}]);
  return $L->Attachment(Filename=>'security_advisories.xlsx',ContentType=>'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',Content=>$X);
 }
 if ($Sub eq 'Template') {
  my @Headers=('Class','Name','Description',map {$_->{Name}} @{$M->{Fields}});
  my $X=$Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ExportSheets(Sheets=>[{Name=>'SecurityAdvisory',Head=>\@Headers,Data=>[]}]);
  return $L->Attachment(Filename=>'security_advisory_template.xlsx',ContentType=>'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',Content=>$X);
 }
 if ($Sub eq 'Save' || $Sub eq 'Import' || $Sub eq 'Export') {
  $L->ChallengeTokenCheck();
  my @Rows;
  if ($Sub eq 'Import') {
   my $Payload=$R->GetParam(Param=>'Payload')||'';
   if (length($Payload)>2_000_000) {$Error='Import exceeds 2MB.';}
   else {my $Rows=eval{$Kernel::OM->Get('Kernel::System::JSON')->Decode(Data=>$Payload)};
    if (ref $Rows ne 'ARRAY' || @$Rows>500) {$Error='Import must contain at most 500 advisory rows.';} else {@Rows=@$Rows;}}
  } else {
   my %Row=(Class=>'SecurityAdvisory',Name=>$R->GetParam(Param=>'Name')||'',Description=>$R->GetParam(Param=>'Description')||'');
   for my $F (@{$M->{Fields}}) {$Row{$F->{Name}}=($F->{Config}{MultiValue} && $F->{Name} ne 'AdvancedCondition')?[$R->GetArray(Param=>$F->{Name})]:($R->GetParam(Param=>$F->{Name})//'');}
   if (($R->GetParam(Param=>'ConditionMode')||'Products') eq 'Products') {
    my $Y=eval{$S->ProductCondition(Model=>$M,ProductIDs=>[$R->GetArray(Param=>'ProductIDs')])};
    if ($@) {$Error='Select at least one valid Product.';} else {$Row{AdvancedCondition}=$Y;}
   }
   push @Rows,\%Row;
  }
  if (!$Error && $Sub eq 'Export') {
   my @Headers=('Class','Name','Description',map {$_->{Name}} @{$M->{Fields}});
   my @Data;
   for my $Row (@Rows) {for my $F (@{$M->{Fields}}) {next if $F->{FieldType} !~ /\A(?:ConfigItem|GovernanceObject)\z/;my %C=map {$_->{ID}=>$_->{Name}} @{$F->{Choices}};my $V=$Row->{$F->{Name}}; $Row->{$F->{Name}}=ref $V eq 'ARRAY'?[map {$C{$_}//$_} @$V]:$C{$V}//$V;}push @Data,[map {ref $Row->{$_}?$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$Row->{$_}):$Row->{$_}//''} @Headers];}
   my $X=$Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ExportSheets(Sheets=>[{Name=>'SecurityAdvisory',Head=>\@Headers,Data=>\@Data}]);
   return $L->Attachment(Filename=>'security_advisory.xlsx',ContentType=>'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',Content=>$X);
  }
  my %Attachments;
  for my $Slot (1) {
   my %A=$R->GetUploadAll(Param=>'Attachment'.$Slot);
   next if !$A{Filename};
   my $Row=$Sub eq 'Import' ? $R->GetParam(Param=>'AttachmentRow'.$Slot) : 1;
   if (!$Row || $Row!~/\A[0-9]+\z/ || $Row>@Rows) {$Error='Each attachment must name a valid preview row.';last;}
   if (length($A{Content}//'')>5*1024*1024) {$Error='Attachment exceeds 5MB.';last;}
   push @{$Attachments{$Row}},\%A;
  }
  my $Submission=$R->GetParam(Param=>'SubmissionToken')||'';
  $Error='Invalid submission token. Reload the page.' if $Submission!~/\A[A-Za-z0-9]{32}(?:save|import)\z/;
  if (!$Error) {
   my $Key='SecurityAdvisory:'.$Self->{UserID}.':'.($R->GetParam(Param=>'SubmissionToken')||'');
   my $Cache=$Kernel::OM->Get('Kernel::System::Cache');my $Prior=$Cache->Get(Type=>'TESSERAAdvisory',Key=>$Key);
   if ($Prior) {@Results=@$Prior;}
   else {
    my $PID=$Kernel::OM->Get('Kernel::System::PID');my $Lock='Advisory-'.sha256_hex($Key);
    if (!$PID->PIDCreate(Name=>$Lock)) {$Error='This submission is already processing. Please wait.';}
    else {
     for my $Index (0..$#Rows) {
      my $Result=eval{$S->Create(Row=>$Rows[$Index],Model=>$M,CustomerUserID=>$Self->{UserID},Attachments=>$Attachments{$Index+1}||[])};
      my $E=$@||'';$E=~s/ at .*? line \d+.*//s;$E=~s/\s+/ /g;
      push @Results,{Row=>$Index+1,Message=>$Result?'Created advisory '.$Result->{ConfigItemID}.($Result->{AttachmentWarning}?' - '.$Result->{AttachmentWarning}:''):$E,Success=>$Result?1:0};
     }
     $Cache->Set(Type=>'TESSERAAdvisory',Key=>$Key,Value=>\@Results,TTL=>3600);
     $PID->PIDDelete(Name=>$Lock);
    }
   }
  }
 }
 $Overview=$S->Overview(CustomerUserID=>$Self->{UserID},Model=>$M) if @Results;
 my $Selected=$R->GetParam(Param=>'AdvisoryMetric')||'';
 my ($Metric)=grep {$_->{Key} eq $Selected} @{$Overview->{Metrics}};
 $Overview->{SelectedMetric}=$Metric->{Key} if $Metric;
 $Overview->{SelectedLabel}=$Metric->{Label} if $Metric;
 $Overview->{DetailRows}=$Overview->{Groups}{$Metric->{Key}} if $Metric;
 # Defaults apply only to the initial single form; bulk import never hydrates Application.
 for my $F (@{$M->{Fields}}) {
  my $Value=$R->GetParam(Param=>$F->{Name});
  $F->{Value}=$Value if defined $Value;
  my @V=$F->{Config}{MultiValue}?$R->GetArray(Param=>$F->{Name}):($F->{Value}//'');
  my %Selected=map {$_=>1} @V;
  for my $C (@{$F->{Choices}}) {$C->{Selected}=$Selected{$C->{ID}}?1:0;}
 }
 my $Token=$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>32);
 $L->CustomerSetRichTextParameters(Data=>{});
 my $Out=$L->CustomerHeader(Title=>'Security Advisory').$L->CustomerNavigationBar();
 $Out.=$L->Output(TemplateFile=>'CustomerSecurityAdvisory',Data=>{%$M,%$Overview,IsDashboard=>$View eq 'Dashboard',ShowForm=>($Error && $Sub eq 'Save')?1:0,Results=>\@Results,Error=>$Error,SubmissionToken=>$Token,Name=>$R->GetParam(Param=>'Name')||'',Description=>$R->GetParam(Param=>'Description')||''});
 return $Out.$L->CustomerFooter();
}
1;
