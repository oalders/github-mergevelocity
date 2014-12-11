package Github::MergeVelocity::PullRequest;

use Moose;

use DateTime;
use Github::MergeVelocity::Types qw( Datetime );
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

    return $upper_bound->delta_days( $self->created_at )->days;
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
package Github::MergeVelocity::Types;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Type::Library -base, -declare => ( 'Datetime' );
use Type::Utils;
use Types::Standard -types;

class_type Datetime, { class => "DateTime" };

coerce Datetime, from Str,
    via { DateTime::Format::ISO8601->parse_datetime( $_ ) };
1;
package Github::MergeVelocity;

use strict;
use warnings;
use feature qw( say );

use CHI;
use CLDR::Number::Format::Percent;
use Data::Printer;
use Github::MergeVelocity::PullRequest;
use HTTP::Tiny::Mech;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use Math::Round qw( round );
use MetaCPAN::Client;
use Moose;
use MooseX::Getopt::Dashes;
use MooseX::StrictConstructor;
use Pithub::PullRequests;
use Text::SimpleTable::AutoWidth;
use Types::Standard qw( ArrayRef Bool Str );
use Unicode::Char;
use WWW::Mechanize::Cached;

with 'MooseX::Getopt::Dashes';

has debug_useragent => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Print a _lot_ of debugging info about LWP requests',
);

my $token_help = <<'EOF';
Please see
https://help.github.com/articles/creating-an-access-token-for-command-line-use
for instructions on how to get your own Github access token.
EOF

has cache_requests => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Try to cache GET requests',
);

has dist => (
    is       => 'ro',
    isa      => ArrayRef,
    traits   => ['Array'],
    handles  => { _all_lookups => 'elements' },
    required => 1,
    documentation =>
        'One or more distributions to look up. You can add multiple --dist args.',
);

has github_token => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    documentation => $token_help,
);

has github_user => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    documentation => 'The username of your Github account',
);

has report => (
    is       => 'ro',
    isa      => ArrayRef,
    traits   => ['Array'],
    init_arg => undef,
    handles  => { '_report_rows' => 'elements' },
    lazy     => 1,
    builder  => '_build_report',
);

has _char => (
    is      => 'ro',
    isa     => 'Unicode::Char',
    handles => { _naughty => 'warning_sign', _nice => 'father_christmas', },
    lazy    => 1,
    default => sub { Unicode::Char->new },
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
    builder => '_build_metacpan_client',
);

has _repositories => (
    is      => 'ro',
    isa     => ArrayRef,
    traits  => ['Array'],
    handles => { '_all_repositories' => 'elements' },
    lazy    => 1,
    builder => '_build_repositories',
);

has _percent_formatter => (
    is      => 'ro',
    isa     => 'CLDR::Number::Format::Percent',
    handles => { '_format_percent' => 'format' },
    lazy    => 1,
    default => sub { CLDR::Number::Format::Percent->new( locale => 'en' ) },
);

sub _build_github_client {
    my $self = shift;
    return Pithub::PullRequests->new(
        $self->cache_requests
            || $self->debug_useragent ? ( ua => $self->_mech ) : (),
        $self->github_user  ? ( user  => $self->github_user )  : (),
        $self->github_token ? ( token => $self->github_token ) : (),
    );
}

sub _build_mech {
    my $self = shift;

    my $mech;

    if ( $self->cache_requests ) {
        $mech = WWW::Mechanize::Cached->new(
            cache => CHI->new(
                driver   => 'File',
                root_dir => '/tmp/metacpan-cache',
            )
        );
    }
    else {
        $mech = WWW::Mechanize->new;
    }

    debug_ua( $mech ) if $self->debug_useragent;
    return $mech;
}

sub _build_metacpan_client {
    my $self = shift;

    my %args;
    if ( $self->cache_requests || $self->debug_useragent ) {
        $args{ua} = HTTP::Tiny::Mech->new( mechua => $self->_mech );
    }

    return MetaCPAN::Client->new( %args );
}

sub _build_report {
    my $self = shift;

    my @report;

    foreach my $repo_url ( $self->_all_repositories ) {
        my ( $user, $repo ) = $self->_parse_github_url( $repo_url );

        if ( !( $user && $repo ) ) {
            warn "Could not parse $repo_url";
            next;
        }

        my $report = $self->_analyze_repo( $user, $repo );
        push @report, $report if $report;
    }
    return \@report;
}

sub _build_repositories {
    my $self = shift;

    my @either = map { +{ distribution => $_ } } $self->_all_lookups;

    my $query
        = { all => [ { status => 'latest' }, { either => \@either }, ] };

    my $params = {
        fields => [qw(distribution resources)],
        size   => 250,
    };

    my $resultset = $self->_metacpan_client->release( $query, $params );
    my @repositories;
    while ( my $dist = $resultset->next ) {
        if ( !exists $dist->resources->{repository}->{url} ) {
            warn 'No repo found for ' . $dist->distribution;
            next;
        }
        push @repositories, $dist->resources->{repository}->{url};
    }
    return \@repositories;
}

sub print_report {
    my $self = shift;

    my $table = Text::SimpleTable::AutoWidth->new;
    my @cols  = (
        q{},      'user',           'repo', 'PRs',
        'merged', 'avg merge days', 'open', 'avg open days',
        'closed', 'avg close days'
    );
    $table->captions( \@cols );

    foreach my $row ( $self->_report_rows ) {
        $table->row(
            $row->{is_nice} ? $self->_nice : $self->_naughty,
            $row->{user},
            $row->{repo},
            $row->{total},
            $self->_format_percent( $row->{percentage_merged} ),
            $row->{merged_age},
            $self->_format_percent( $row->{percentage_open} ),
            $row->{open_age},
            $self->_format_percent( $row->{percentage_closed} ),
            $row->{closed_age},
        );
    }

    binmode( STDOUT, ':utf8' );
    print $table->draw;
    return;
}

sub _analyze_repo {
    my $self = shift;
    my $user = shift;
    my $repo = shift;

    my $pulls = $self->_get_pull_requests( $user, $repo );
    my $total = $pulls ? scalar @{$pulls} : 0;

    my %summary = (
        closed     => 0,
        merged     => 0,
        open       => 0,
        repo       => $repo,
        closed_age => 0,
        merged_age => 0,
        open_age   => 0,
        total      => $total,
        user       => $user,
    );

    foreach my $pr ( @{$pulls} ) {
        $summary{ $pr->state }++;
        $summary{ $pr->state . '_age' } += $pr->age;
    }

    foreach my $state ( 'closed', 'merged', 'open' ) {
        my $percent = $total ? $summary{$state} / $total : 0;
        $summary{ 'percentage_' . $state } = $percent;
    }

    $summary{is_nice}
        = ( $summary{percentage_merged} >= .75 && $summary{merged_age} < 40 )
        || ( $summary{merged_age} < 30
        && $summary{closed_age} < 30
        && $summary{percentage_open} <= .25 )
        || ( $summary{open_age} < 365
        && $summary{percentage_open} < .15 );

    return \%summary;
}

sub _get_pull_requests {
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
            created_at => $row->{created_at},
            $row->{closed_at} ? ( closed_at => $row->{closed_at} ) : (),
            $row->{merged_at} ? ( merged_at => $row->{merged_at} ) : (),
        );

        push @pulls, $pull_request;
    }
    return \@pulls;
}

sub _parse_github_url {
    my $self = shift;
    my $url  = shift;

    my @parts = split qr{[/:]}, $url;

    my $repo = pop @parts;
    my $user = pop @parts;
    $repo =~ s{\.git}{};

    return ( $user, $repo );
}

__PACKAGE__->meta->make_immutable();
1;


package main;

use strict;
use warnings;

use Github::MergeVelocity;

Github::MergeVelocity->new_with_options->print_report;

