package Math::Calc::Units::Convert::Time;
use base 'Math::Calc::Units::Convert::Metric';
use strict;
use vars qw(%units %pref %ranges %total_unit_map);

%units = ( minute => [ 60, 'sec' ],
	   hour => [ 60, 'minute' ],
	   day => [ 24, 'hour' ],
	   week => [ 7, 'day' ],
);

%pref = ( default => 1,
	  hour => 0.8,
	  day => 0.8,
	  week => 0.4,
	  minute => 0.9,
);

%ranges = ( default => [ 1, 300 ],
	    millisec => [ 1, 999 ],
	    sec => [ 1, 200 ],
	    minute => [ 2, 100 ],
	    hour => [ 1, 80 ],
	    day => [ 1, undef ],
	    week => [ 1, 4 ],
);

sub major_pref {
    return 2;
}

sub major_variants {
    my ($self) = @_;
    return grep { ($_ ne 'default') && ($_ ne 'week') } keys %ranges;
}

# Return a list of the variants of the canonical unit of time: 'sec'
sub variants {
    my ($self, $base) = @_;
    return 'sec', (keys %units), map { "${_}sec" } $self->get_prefixes();
}

sub unit_map {
    my ($self) = @_;
    if (keys %total_unit_map == 0) {
	%total_unit_map = (%{$self->SUPER::unit_map()}, %units);
    }
    return \%total_unit_map;
}

sub canonical_unit { return 'sec'; }

# demetric : string => [ mult, base ]
#
# Must override here to avoid megahours or milliweeks
#
sub demetric {
    my ($self, $string) = @_;
    if (my $prefix = $self->get_prefix($string)) {
	my $tail = substr($string, length($prefix));
	if ($tail =~ /^sec(ond)?s?$/) {
	    return ($self->get_metric($prefix), $tail);
	}
	return; # Should this fail, or assume it's a non-metric unit?
    } else {
	return (1, $string);
    }
}

# simple_convert : unitName x unitName -> multiplier
#
# Does not allow msec (only millisec or ms)
#
sub simple_convert {
    my ($self, $from, $to) = @_;

    # sec, secs, second, seconds
    $from = "sec" if $from =~ /^sec(ond)?s?$/i;
    $from = "minute" if $from =~ /^min(ute)?s?$/i;

    if (my $easy = $self->SUPER::simple_convert($from, $to)) {
	return $easy;
    }

    # ms == millisec
    if ($from =~ /^(.)s$/) {
	my @expansions = $self->expand($1);
	# Only use prefixes smaller than one, and pick the first
	foreach my $expansion ($self->expand($1)) {
	    my $full = $expansion . "sec";
	    my ($mult, $base) = $self->demetric($full);
	    if ($mult < 1) {
		return $self->simple_convert($full, $to);
	    }
	}
    }

    return; # Failed
}

##############################################################################

sub describe {
    my $self = shift;
    my $v = shift;
    die "Huh? Can only do seconds!" if $v->[1] ne 'sec';
    my @spread = $self->spread($v, 'week', 'day', 'hour', 'minute', 'sec',
			       'ms', 'us', 'ns', 'ps');
    return (\@spread, $v); # Hmm... what type am I returning??
}

sub preference {
    my ($self, $v) = @_;
    my ($val, $unit) = @$v;
    my $base = lc(($self->demetric($unit))[1]);
    my $pref = $pref{$base} || $pref{default};
    return $pref * $self->prefix_pref(substr($unit, 0, -length($base)));
}

sub get_ranges {
    return \%ranges;
}

sub get_prefs {
    return \%pref;
}

1;
