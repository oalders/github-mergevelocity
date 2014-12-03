package Github::MergeVelocity;

use strict;
use warnings;
use feature qw( say );

use CHI;
use Data::Printer;
use DateTime;
use DateTime::Format::ISO8601;
use Github::MergeVelocity::PullRequest;
use HTTP::Tiny::Mech;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use MetaCPAN::Client;
use Moose;
use MooseX::Getopt::Dashes;
use Pithub::PullRequests;
use WWW::Mechanize::Cached;

with 'MooseX::Getopt::Dashes';

has debug_useragent => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => 'Print a _lot_ of debugging info about LWP requests',
);

my $token_help = <<'EOF';
Please see
https://help.github.com/articles/creating-an-access-token-for-command-line-use
for instructions on how to get your own Github access token.
EOF

has cache_requests => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => 'Try to cache GET requests',
);

has github_token => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => $token_help,
);

has github_user => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => 'The username of your Github account',
);

has _github_client => (
    is      => 'ro',
    isa     => 'Pithub::PullRequests',
    lazy    => 1,
    builder => '_build_github_client'
);

has _mech => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    builder => '_build_mech',
);

has _metacpan_client => (
    is      => 'ro',
    isa     => 'MetaCPAN::Client',
    lazy    => 1,
    default => sub {
        return MetaCPAN::Client->new(
            ua => HTTP::Tiny::Mech->new( mechua => $_[0]->_mech ) );
    },
);

sub _build_github_client {
    my $self = shift;
    return Pithub::PullRequests->new(
        ua    => $self->_mech,
        user  => $self->github_user,
        token => $self->github_token
    );
}

sub _build_mech {
    my $self = shift;

    my $mech
        = $self->cache_requests
        ? WWW::Mechanize::Cached->new(
        cache => CHI->new(
            driver   => 'File',
            root_dir => '/tmp/metacpan-cache',
        )
        )
        : WWW::Mechanize->new;

    debug_ua( $mech ) if $self->debug_useragent;
    return $mech;
}

sub run {
    my $self = shift;

    my $dists = $self->_get_distributions;

    foreach my $dist ( %{$dists} ) {
        my $repo_url = $dists->{$dist}->{repo};
        next if !$repo_url;

        my ( $user, $repo ) = $self->_parse_github_url( $repo_url );

        next unless $user && $repo;

        my $velocity = $self->get_merge_velocity( $user, $repo );
        $dists->{$dist}->{velocity} = $velocity;
    }
}

sub _get_distributions {
    my $self  = shift;
    my $query = {
        all => [
            { status                     => 'latest' },
            { 'resources.repository.url' => '*github*' }
        ]
    };
    my $params = {
        fields => [qw(distribution author date version resources)],
        size   => 50
    };
    my $result_set = $self->_metacpan_client->release( $query, $params );
    my %dist;

    while ( my $release = $result_set->next ) {
        my $distname = $release->distribution;
        next
            if $distname
            =~ /^(Acme|Task-BeLike|Dist-Zilla-PluginBundle-Author)/;

        if ( !exists( $dist{$distname} )
            || $dist{$distname}{date} lt $release->date )
        {
            $dist{$distname} = {
                author  => $release->author,
                date    => $release->date,
                repo    => $release->resources->{repository}->{url},
                version => $release->version,
            };
        }
        last if keys %dist > 50;
    }
    return \%dist;
}

sub get_merge_velocity {
    my $self = shift;
    my $user = shift;
    my $repo = shift;

    my $pulls = $self->get_pull_requests( $user, $repo );
    my $velocity = $self->calculate_velocity( $pulls );
}

sub get_pull_requests {
    my $self = shift;
    my $user = shift;
    my $repo = shift;

    my $result = $self->_github_client->list(
        user   => $user,
        repo   => $repo,
        params => { per_page => 100, state => 'all' },
    );

    my @pulls;
    while ( my $row = $result->next ) {

        # GunioRobot seems to create pull requests that clean up whitespace
        return if !$row->{user} || $row->{user}->{login} eq 'GunioRobot';

        my @args = map { $_ => $row->{$_} }
            grep { exists $row->{$_} && $row->{$_} } (
            'closed_at',  'created_at', 'merged_at', 'number',
            'updated_at', 'url',
            );

        my $pull_request = Github::MergeVelocity::PullRequest->new(
            login => $row->{user}->{login},
            @args
        );

        push @pulls, $pull_request;
    }
    return \@pulls;
}

sub calculate_velocity {
    my $self          = shift;
    my $pull_requests = shift;

    my %states;

    foreach my $pr ( @{$pull_requests} ) {
        $states{ $pr->state }++;
    }
    p %states;

    # merged / closed
    # open / (open + closed)
    # total time open / open
    # total time to merge / merged
    # total time to close / closed
}

sub _parse_github_url {
    my $self = shift;
    my $url  = shift;

    print "parsing $url\n";
    my @parts = split '/', $url;

    my $repo = pop @parts;
    my $user = pop @parts;
    $repo =~ s{\.git}{};

    return ( $user, $repo );
}

__PACKAGE__->meta->make_immutable();
1;

