package Github::MergeVelocity::PullRequest;

use Moose;

use DateTime;
use Github::MergeVelocity::Types qw( Datetime );
use Types::Standard qw( Int Str );

has age => (
    is       => 'ro',
    init_arg => undef,
    isa      => Int,
    lazy     => 1,
    builder  => '_build_age',
);

has closed_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_closed_at',
    coerce    => 1,
);

has created_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_created_at',
    coerce    => 1,
    required  => 1,
);

has login => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has merged_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_merged_at',
    coerce    => 1,
);

has state => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_state',
);

has url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has updated_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_updated_at',
    coerce    => 1,
    required  => 1,
);

sub _build_age {
    my $self = shift;

    my $upper_bound
        = $self->has_merged_at ? $self->merged_at
        : $self->has_closed_at ? $self->closed_at
        :                        DateTime->now;

    my $duration
        = $upper_bound->subtract_datetime_absolute( $self->created_at );
    return $duration->in_units( 'seconds' );
}

sub is_merged {
    my $self = shift;
    return $self->has_merged_at;
}

sub _build_state {
    my $self = shift;
    return
          $self->has_merged_at ? 'merged'
        : $self->has_closed_at ? 'closed'
        :                        'open';
}

__PACKAGE__->meta->make_immutable;
1;
