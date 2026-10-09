package Kernel::System::TESSERA::Questionnaire;
use strict;
use warnings;
use Math::BigRat;
our @ObjectDependencies = ();
sub new { bless {}, shift }

# Generic answer mappings and aggregation. No questionnaire fields or weights live here.
sub Evaluate {
    my ($Self, %P) = @_;
    my $Config = $P{Config};
    die "Questionnaire BASE must be a mapping.\n" if ref $Config ne 'HASH';
    my %Result;
    for my $Dimension (qw(IMPACT LIKELIHOOD)) {
        my $Rule = $Config->{$Dimension};
        die "Questionnaire $Dimension rule is invalid.\n" if ref $Rule ne 'HASH'
            || ($Rule->{AGGREGATE} || '') ne 'PRODUCT' || ($Rule->{ROUND} || '') ne 'CEILING'
            || ref $Rule->{QUESTIONS} ne 'ARRAY' || !@{$Rule->{QUESTIONS}};
        my $Scale = $Self->_Value($P{Framework}, $Rule->{'SCALE FIELD'});
        die "Questionnaire scale must be a positive integer.\n" if !defined $Scale || ref $Scale || $Scale !~ /\A[1-9][0-9]*\z/;
        my $Product = Math::BigRat->new(1);
        my (@Evidence, %Seen);
        for my $Question (@{$Rule->{QUESTIONS}}) {
            die "Questionnaire entry is invalid or duplicated.\n" if ref $Question ne 'HASH'
                || !$Question->{FIELD} || $Seen{$Question->{FIELD}}++ || ref $Question->{VALUES} ne 'HASH';
            # Validate every authored mapping, including answers not selected this run.
            for my $Weight (values %{$Question->{VALUES}}) {
                die "Questionnaire modifier must be a decimal between zero and one.\n"
                    if !defined $Weight || ref $Weight || $Weight !~ /\A(?:0(?:\.\d+)?|1(?:\.0+)?)\z/;
            }
            my $Answer = $Self->_Value($P{Object}, $Question->{FIELD});
            $Answer = $Question->{'WHEN MISSING'} if !defined $Answer || $Answer eq '';
            die "Unmapped questionnaire answer for $Question->{FIELD}.\n"
                if !defined $Answer || ref $Answer || !exists $Question->{VALUES}{$Answer};
            my $Weight = $Question->{VALUES}{$Answer};
            $Product->bmul(Math::BigRat->new($Weight));
            push @Evidence, {Field=>$Question->{FIELD}, Answer=>$Answer, Modifier=>"$Weight"};
        }
        my $Raw = $Product->copy->bmul($Scale);
        my $Base = $Raw->copy->bceil;
        my $Minimum = $Rule->{MINIMUM};
        die "Questionnaire minimum must be an integer within the scale.\n"
            if !defined $Minimum || ref $Minimum || $Minimum !~ /\A\d+\z/ || $Minimum > $Scale;
        $Base = Math::BigRat->new($Minimum) if $Base < $Minimum;
        $Result{$Dimension} = {Base=>0+$Base->bstr, Scale=>0+$Scale,
            Modifier=>$Product->bstr, Raw=>$Raw->bstr, Answers=>\@Evidence};
    }
    return \%Result;
}
sub _Value {
    my ($Self, $Object, $Field) = @_;
    die "Questionnaire field path is invalid.\n" if !defined $Field || $Field !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    return exists $Object->{$Field} ? $Object->{$Field} : $Object->{'DynamicField_'.$Field};
}
1;
