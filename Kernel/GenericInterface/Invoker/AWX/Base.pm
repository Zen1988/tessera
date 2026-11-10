package Kernel::GenericInterface::Invoker::AWX::Base;

use strict;
use warnings;
use Scalar::Util qw(refaddr blessed);
use Storable qw(dclone);

our $ObjectManagerDisabled = 1;

sub new {
    my ($Type, %Param) = @_;
    return {Success => 0, ErrorMessage => 'Missing debugger.'} if !$Param{DebuggerObject};
    return bless { %Param }, $Type;
}

sub _Error {
    my ($Self, $Message, %Data) = @_;
    return {Success => 0, ErrorMessage => $Message, Data => { %Data }};
}

sub _ID { return defined $_[0] && !ref $_[0] && $_[0] =~ /\A[1-9][0-9]{0,14}\z/ }

sub _ConfigurationError {
    my ($Self) = @_;
    my $WS = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID => $Self->{WebserviceID});
    return 'AWX web service is unavailable.' if ref $WS ne 'HASH' || ($WS->{ValidID} || 0) != 1;
    my $R = $WS->{Config}{Requester};
    my $T = $R->{Transport};
    return 'AWX requires HTTP::REST.' if ($T->{Type} || '') ne 'HTTP::REST';
    my $C = $T->{Config};
    return 'AWX requires HTTPS without URL credentials.'
        if ($C->{Host} || '') !~ m{\Ahttps://[A-Za-z0-9.-]+(?::[0-9]+)?/?\z};
    return 'AWX timeout must be between 1 and 60 seconds.'
        if ($C->{Timeout} || '') !~ /\A[0-9]+\z/ || $C->{Timeout} < 1 || $C->{Timeout} > 60;
    return 'AWX TLS verification cannot be disabled.'
        if ($C->{SSL}{SSLVerifyHostname} || '') eq 'No' || ($C->{SSL}{SSLVerifyMode} || '') eq 'No';
    my ($Resource, $Launch, $Kind) = $Self->_Spec();
    my $Expected = '/api/v2/' . $Resource . '/:' . ($Launch ? 'TemplateID/launch/' : 'JobID/');
    $Expected .= 'stdout/' if ($Kind || '') eq 'stdout';
    $Expected .= 'job_events/' if ($Kind || '') eq 'events';
    $Expected .= 'workflow_nodes/' if ($Kind || '') eq 'nodes';
    my $Method = $Launch ? 'POST' : 'GET';
    ($Expected, $Method) = $Self->_Endpoint() if $Self->can('_Endpoint');
    my $Route = $C->{InvokerControllerMapping}{$Self->{Invoker}};
    return 'AWX requires the documented controller and HTTP method.'
        if ($Route->{Controller} || '') ne $Expected || ($Route->{Command} || '') ne $Method;
    my $I = $R->{Invoker}{$Self->{Invoker}};
    for my $Direction (qw(MappingInbound MappingOutbound)) {
        return 'AWX invokers require empty mappings.' if ref $I->{$Direction} eq 'HASH' && keys %{$I->{$Direction}};
    }
    return;
}

# Bounded JSON data, never YAML, code, object instances or cyclic references.
sub _DataOK {
    my ($Value) = @_;
    my ($Nodes, $Bytes, %Active) = (0, 0);
    my $Walk;
    $Walk = sub {
        my ($V, $Depth) = @_;
        die if ++$Nodes > 10000 || $Depth > 32;
        if (!ref $V) { $Bytes += defined $V ? length($V) : 0; die if $Bytes > 1048576; return }
        return if blessed($V) && blessed($V) =~ /\A(?:JSON::PP::Boolean|JSON::XS::Boolean|Types::Serialiser::Boolean)\z/;
        die if ref $V ne 'HASH' && ref $V ne 'ARRAY';
        my $Address = refaddr($V);
        die if $Active{$Address};
        local $Active{$Address} = 1;
        if (ref $V eq 'HASH') { for my $Key (keys %{$V}) { $Walk->($Key, $Depth + 1); $Walk->($V->{$Key}, $Depth + 1) } }
        else { $Walk->($_, $Depth + 1) for @{$V} }
    };
    my $OK = eval { $Walk->($Value, 0); 1 };
    undef $Walk;
    return $OK;
}

# Payloads are non-secret data. This catches common credential overrides; it is
# not a classifier for secrets hidden under arbitrary business-variable names.
sub _CredentialKey {
    my ($Value) = @_;
    if (ref $Value eq 'HASH') {
        for my $Key (keys %{$Value}) {
            return 1 if $Key =~ /\A(?:credentials?|credential_ids?|credential_passwords|password|passwd|ssh_private_key|private_key|vault_password|become_password|ansible_password|ansible_ssh_pass|ansible_become_password|ansible_ssh_private_key_file|authorization|api_token|access_token|callbacktoken)\z/i;
            return 1 if _CredentialKey($Value->{$Key});
        }
    }
    elsif (ref $Value eq 'ARRAY') { for (@{$Value}) { return 1 if _CredentialKey($_) } }
    return 0;
}

sub PrepareRequest {
    my ($Self, %Param) = @_;
    delete $Self->{RequestedID};
    my $D = $Param{Data};
    return $Self->_Error('AWX input must be a bounded JSON object.') if ref $D ne 'HASH' || !_DataOK($D);
    my $Callback;
    if ($Self->can('_CallbackLaunch')) {
        $D = dclone($D);
        my $UID = delete $D->{ExecutionUID};
        my $Token = delete $D->{CallbackToken};
        return $Self->_Error('Missing execution-scoped callback identity.') if !defined $UID || ref $UID || $UID !~ /\A[A-Za-z0-9]{40}\z/
            || !defined $Token || ref $Token || $Token !~ /\A[A-Za-z0-9]{64}\z/;
        my $URL = $Kernel::OM->Get('Kernel::Config')->Get('TESSERA::AWX::CallbackURL');
        return $Self->_Error('Configure the HTTPS TESSERA callback endpoint first.')
            if !defined $URL || ref $URL || $URL !~ m{\Ahttps://[A-Za-z0-9.-]+(?::[0-9]+)?/[A-Za-z0-9_./%-]+/ExecutionCallback\z};
        return $Self->_Error('The tessera_callback variable is reserved.') if ref $D->{extra_vars} eq 'HASH' && exists $D->{extra_vars}{tessera_callback};
        $Callback = {ExecutionUID => $UID, CallbackToken => $Token, URL => $URL};
    }
    return $Self->_Error('AWX payload must not contain credential overrides or secrets.') if _CredentialKey($D);
    my $ConfigError = $Self->_ConfigurationError();
    return $Self->_Error($ConfigError) if $ConfigError;
    my ($Resource, $Launch, $Kind) = $Self->_Spec();
    $Kind ||= '';
    my $IDKey = $Launch ? 'TemplateID' : 'JobID';
    return $Self->_Error("AWX requires a positive $IDKey.") if !_ID($D->{$IDKey});
    my %Allowed = map { $_ => 1 } ($IDKey, $Launch ? qw(inventory extra_vars limit job_tags skip_tags scm_branch job_type verbosity forks timeout diff_mode job_slice_count) : ());
    $Allowed{$_} = 1 for $Kind eq 'stdout' ? qw(start_line end_line) : $Kind ? qw(page page_size) : ();
    return $Self->_Error('Unsupported AWX input; credentials, authentication and callback tokens are not accepted.')
        if grep { !$Allowed{$_} } keys %{$D};
    if ($Launch) {
        return $Self->_Error('AWX inventory must be an existing inventory ID.')
            if exists $D->{inventory} && !_ID($D->{inventory});
        return $Self->_Error('AWX extra_vars must be a JSON object.')
            if exists $D->{extra_vars} && ref $D->{extra_vars} ne 'HASH';
        for my $Key (qw(limit job_tags skip_tags scm_branch job_type)) {
            return $Self->_Error("Invalid AWX $Key.") if exists $D->{$Key} && (!defined $D->{$Key} || ref $D->{$Key} || length($D->{$Key}) > 4096);
        }
        return $Self->_Error('Invalid AWX job_type.') if exists $D->{job_type} && $D->{job_type} !~ /\A(?:run|check)\z/;
        for my $Key (qw(verbosity forks timeout job_slice_count)) {
            return $Self->_Error("Invalid AWX $Key.") if exists $D->{$Key}
                && (!defined $D->{$Key} || ref $D->{$Key} || $D->{$Key} !~ /\A[0-9]{1,6}\z/);
        }
        return $Self->_Error('Invalid AWX verbosity.') if exists $D->{verbosity} && $D->{verbosity} > 5;
        return $Self->_Error('Invalid AWX job_slice_count.') if exists $D->{job_slice_count} && !$D->{job_slice_count};
        return $Self->_Error('Invalid AWX diff_mode.') if exists $D->{diff_mode}
            && !(defined $D->{diff_mode} && ((!ref $D->{diff_mode} && $D->{diff_mode} =~ /\A[01]\z/) || blessed($D->{diff_mode})));
    }
    $Self->{RequestedID} = $D->{$IDKey};
    my $Out = dclone($D);
    if ($Callback) { $Out->{extra_vars} ||= {}; $Out->{extra_vars}{tessera_callback} = $Callback }
    if ($Kind eq 'stdout') {
        for my $Key (qw(start_line end_line)) {
            return $Self->_Error('Invalid stdout line range.') if exists $D->{$Key}
                && (!defined $D->{$Key} || ref $D->{$Key} || $D->{$Key} !~ /\A[0-9]{1,10}\z/);
        }
        $Out->{start_line} //= 0;
        $Out->{end_line} //= $Out->{start_line} + 200;
        return $Self->_Error('Stdout requests must span 1 to 1000 lines.')
            if $Out->{end_line} <= $Out->{start_line} || $Out->{end_line} - $Out->{start_line} > 1000;
        $Out->{format} = 'json';
    }
    elsif ($Kind) {
        $Out->{page} //= 1;
        $Out->{page_size} //= 100;
        return $Self->_Error('Invalid AWX page or page_size.') if !_ID($Out->{page}) || !_ID($Out->{page_size}) || $Out->{page_size} > 200;
        $Out->{order_by} = $Kind eq 'events' ? 'counter' : 'id';
    }
    return {Success => 1, Data => $Out};
}

sub HandleResponse {
    my ($Self, %Param) = @_;
    my (undef, $Launch, $Kind) = $Self->_Spec();
    # Never echo remote error bodies, variables or credentials into callers' evidence.
    return $Self->_Error('AWX request failed; reconcile a launch before retrying.', Outcome => $Launch ? 'UNKNOWN' : 'REQUEST_ERROR')
        if !$Param{ResponseSuccess};
    my $D = $Param{Data};
    return $Self->_Error('Invalid or oversized AWX response; request a smaller output page.', Outcome => 'UNKNOWN')
        if ref $D ne 'HASH' || !_DataOK($D);
    if (($Kind || '') eq 'stdout') {
        return $Self->_Error('Invalid AWX stdout response.') if !defined $D->{content} || ref $D->{content} || ref $D->{range} ne 'HASH';
        for my $Key (qw(start end absolute_end)) {
            return $Self->_Error('Invalid AWX stdout range.') if !defined $D->{range}{$Key} || ref $D->{range}{$Key} || $D->{range}{$Key} !~ /\A[0-9]+\z/;
        }
        return {Success => 1, Data => {JobID => $Self->{RequestedID}, Response => dclone($D)}};
    }
    if ($Kind) {
        return $Self->_Error('Invalid AWX output collection.') if ref $D->{results} ne 'ARRAY'
            || !defined $D->{count} || ref $D->{count} || $D->{count} !~ /\A[0-9]+\z/
            || (defined $D->{next} && ref $D->{next}) || (defined $D->{previous} && ref $D->{previous});
        return {Success => 1, Data => {JobID => $Self->{RequestedID}, Response => dclone($D)}};
    }
    return $Self->_Error('Invalid AWX job identity.', Outcome => 'UNKNOWN') if !_ID($D->{id});
    return $Self->_Error('AWX job identity mismatch.', Outcome => 'UNKNOWN')
        if !$Launch && (!defined $Self->{RequestedID} || $D->{id} ne $Self->{RequestedID});
    my $Status = $D->{status};
    my %Statuses = map { $_ => 1 } qw(new pending waiting running successful failed error canceled);
    return $Self->_Error('Unknown AWX job status.', JobID => $D->{id}, Outcome => 'UNKNOWN')
        if !defined $Status || ref $Status || !$Statuses{$Status};
    my $Terminal = $Status =~ /\A(?:successful|failed|error|canceled)\z/ ? 1 : 0;
    my $Result = {JobID => $D->{id}, Status => $Status, Terminal => $Terminal,
        InputAccepted => 1,
        Outcome => !$Terminal ? 'PENDING' : $Status eq 'successful' ? 'SUCCESS' : 'FAILED',
        ExecutionSuccess => $Status eq 'successful' ? 1 : 0, Response => dclone($D)};
    # ignored_fields is returned AFTER launch; the job may already exist. Never retry it.
    if (exists $D->{ignored_fields}) {
        return $Self->_Error('Malformed AWX ignored_fields.', %{$Result}, Outcome => 'UNKNOWN') if ref $D->{ignored_fields} ne 'HASH';
        if (keys %{$D->{ignored_fields}}) {
            return {Success => 1, Data => {%{$Result}, Outcome => 'INPUT_REJECTED', InputAccepted => 0,
                ExecutionSuccess => 0, IgnoredFields => [sort keys %{$D->{ignored_fields}}]}};
        }
    }
    # Preserve the complete response for trusted script consumers. Persisting or
    # presenting it is a separate caller decision: stdout/artifacts may be sensitive.
    return {Success => 1, Data => $Result};
}

1;
