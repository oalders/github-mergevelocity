package Github::MergeVelocity;

use strict;
use warnings;
use feature qw( say );

use CHI;
use CLDR::Number::Format::Percent;
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
use Text::SimpleTable::AutoWidth;
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

has _formatter => (
    is      => 'ro',
    isa     => 'CLDR::Number::Format::Percent',
    handles => ['format'],
    lazy    => 1,
    default => sub { CLDR::Number::Format::Percent->new( locale => 'en' ) },
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
    my @report;

    foreach my $dist ( %{$dists} ) {
        my $repo_url = $dists->{$dist}->{repo};
        next if !$repo_url;

        my ( $user, $repo ) = $self->_parse_github_url( $repo_url );

        next unless $user && $repo;

        my $report = $self->get_report( $user, $repo );
        push @report, $report if $report;
    }
    $self->_print_report( \@report );
}

sub _print_report {
    my $self   = shift;
    my $report = shift;

    my $table = Text::SimpleTable::AutoWidth->new;
    my @cols  = (
        'user', 'repo',         'pull requests', 'merged', 'avg merge age',
        'open', 'avg open age', 'closed', 'avg close age'
    );
    $table->captions( \@cols );

    foreach my $row ( @{$report} ) {

        $table->row(
            $row->{user},
            $row->{repo},
            $row->{total},
            $row->{merged} . " ($row->{merged_open})",
            $row->{merged_age} . ' days',
            $row->{open} . " ($row->{percentage_open})",
            $row->{open_age} . ' days',
            $row->{closed} . " ($row->{percentage_closed})",
            $row->{closed_age} . ' days',
        );
    }
    print $table->draw;
    return;
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
        size   => 250
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
        last if keys %dist > 250;
    }
    return \%dist;
}

sub get_report {
    my $self = shift;
    my $user = shift;
    my $repo = shift;

    my $pulls = $self->get_pull_requests( $user, $repo );

    return $self->analyze_repo( $user, $repo, $pulls );
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
        next if !$row->{user} || $row->{user}->{login} eq 'GunioRobot';

        my $pull_request = Github::MergeVelocity::PullRequest->new(
            login      => $row->{user}->{login},
            created_at => $row->{created_at},
            number     => $row->{number},
            updated_at => $row->{updated_at},
            url        => $row->{url},
            $row->{closed_at} ? ( closed_at => $row->{closed_at} ) : (),
            $row->{merged_at} ? ( merged_at => $row->{merged_at} ) : (),
        );

        push @pulls, $pull_request;
    }
    return \@pulls;
}

sub analyze_repo {
    my $self          = shift;
    my $user          = shift;
    my $repo          = shift;
    my $pull_requests = shift;

    my $total = $pull_requests ? scalar @{$pull_requests} : 0;

    my %summary = (
        closed     => 0,
        merged     => 0,
        open       => 0,
        repo       => $repo,
        closed_age => DateTime::Duration->new,
        merged_age => DateTime::Duration->new,
        open_age   => DateTime::Duration->new,
        total      => $total,
        user       => $user,
    );

    foreach my $pr ( @{$pull_requests} ) {
        $summary{ $pr->state }++;
        if ( $pr->is_merged ) {
            $summary{merged_age}
                = $summary{merged_age}->add_duration( $pr->age );
        }
        elsif ( $pr->is_closed ) {
            $summary{closed_age}
                = $summary{closed_age}->add_duration( $pr->age );
        }
        else {
            $summary{open_age}
                = $summary{open_age}->add_duration( $pr->age );
        }
    }

    my @states = ( 'closed', 'merged', 'open' );
    my @units = ( 'months', 'days', 'hours', 'minutes' );
    foreach my $state ( @states ) {
        $summary{ 'percentage_' . $state }
            = $self->format( $total ? $summary{$state} / $total : 0 );

        my $age_col = $state . '_age';

        if ( !$summary{$state} ) {
            $summary{$age_col} = 0;
            next;
        }

        my ( $years, $months, $days )
            = $summary{$age_col}->in_units( 'years', 'months', 'days' );
        $summary{$age_col}
            = ( $years * 365 + $months * 30 ) / $summary{$state};
    }

    return \%summary;
}

sub _parse_github_url {
    my $self = shift;
    my $url  = shift;

    my @parts = split '/', $url;

    my $repo = pop @parts;
    my $user = pop @parts;
    $repo =~ s{\.git}{};

    return ( $user, $repo );
}

__PACKAGE__->meta->make_immutable();
1;

