package GitHub::MergeVelocity::Repository;

use strict;
use warnings;

use GitHub::MergeVelocity::Repository::PullRequest;
use GitHub::MergeVelocity::Repository::Statistics;
use Moose;
use MooseX::StrictConstructor;
use Types::Standard qw( ArrayRef Bool Str );

has github_client => (
    is       => 'ro',
    isa      => 'Pithub::PullRequests',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ( undef, $name ) = $self->_parse_github_url( $self->url );
        return $name;
    },
);

has report => (
    is       => 'ro',
    isa      => 'GitHub::MergeVelocity::Repository::Statistics',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_report',
);

has url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has user => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my ($user) = $self->_parse_github_url( $self->url );
        return $user;
    },
);

sub _build_report {
    my $self = shift;

    my $pulls = $self->_get_pull_requests;
    my $total = $pulls ? scalar @{$pulls} : 0;

    my %summary;

    foreach my $pr ( @{$pulls} ) {
        $summary{ $pr->state }++;
        $summary{ $pr->state . '_age' } += $pr->age;
    }

    return GitHub::MergeVelocity::Repository::Statistics->new(%summary);
}

sub _get_pull_requests {
    my $self = shift;

    my $result = $self->github_client->list(
        user   => $self->user,
        repo   => $self->name,
        params => { per_page => 100, state => 'all' },
    );

    my @pulls;

    while ( my $row = $result->next ) {

        # GunioRobot seems to create pull requests that clean up whitespace
        next if !$row->{user} || $row->{user}->{login} eq 'GunioRobot';

        my $pull_request
            = GitHub::MergeVelocity::Repository::PullRequest->new(
            created_at => $row->{created_at},
            $row->{closed_at} ? ( closed_at => $row->{closed_at} ) : (),
            $row->{merged_at} ? ( merged_at => $row->{merged_at} ) : (),
            number => $row->{number},
            );

        push @pulls, $pull_request;
    }
    return \@pulls;
}

sub _parse_github_url {
    my $self = shift;
    my $url  = shift;

    my @parts = split qr{[/:]}, $url;

    my $name = pop @parts;
    my $user = pop @parts;
    $name =~ s{\.git}{};

    return ( $user, $name );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

# ABSTRACT: Determine how quickly your pull request might get merged

=pod

=cut
