package GitHub::MergeVelocity::Repository::PullRequest;

use Moose;

use DateTime;
use GitHub::MergeVelocity::Types qw( Datetime );
use MooseX::StrictConstructor;
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
    predicate => 'is_closed',
    coerce    => 1,
);

has created_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_created_at',
    coerce    => 1,
    required  => 1,
);

has merged_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'is_merged',
    coerce    => 1,
);

has number => (
    is            => 'ro',
    isa           => Int,
    required      => 1,
    documentation => 'issue number in the GitHub url'
);

has state => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_state',
);

sub is_open {
    my $self = shift;
    return $self->state eq 'open';
}

sub _build_age {
    my $self = shift;

    my $upper_bound
        = $self->is_merged ? $self->merged_at
        : $self->is_closed ? $self->closed_at
        :                    DateTime->now;

    return $upper_bound->delta_days( $self->created_at )->delta_days;
}

sub _build_state {
    my $self = shift;
    return
          $self->is_merged ? 'merged'
        : $self->is_closed ? 'closed'
        :                    'open';
}

__PACKAGE__->meta->make_immutable;
1;

__END__

# ABSTRACT: Encapsulate select data about GitHub pull requests
