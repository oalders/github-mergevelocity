package GitHub::MergeVelocity::Repository::Statistics;
our $VERSION = '0.000009';
use strict;
use warnings;

use Math::Round qw( nearest round );
use Moo;
use Types::Standard qw( Bool Int );

has average_velocity => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->pull_request_count
            ? round( $self->total_velocity / $self->pull_request_count )
            : 0;
    },
);

has [ 'closed', 'open', 'merged', ] => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has [ 'closed_age', 'open_age', 'merged_age' ] => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has pull_request_count => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->closed + $self->open + $self->merged;
    },
);

has total_velocity => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub average_age_for_state {
    my $self  = shift;
    my $state = shift;

    my $method = $state . '_age';
    return $self->$method
        ? round( $self->$method / $self->$state )
        : 0;
}

sub percentage_in_state {
    my $self  = shift;
    my $state = shift;
    return $self->pull_request_count
        ? nearest( 0.01, $self->$state / $self->pull_request_count )
        : 0;
}

1;

__END__

# ABSTRACT: Pull request statistics for a given repository
