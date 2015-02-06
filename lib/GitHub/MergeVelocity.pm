use strict;
use warnings;

package GitHub::MergeVelocity;

use CHI;
use CLDR::Number::Format::Percent;
use GitHub::MergeVelocity::Repository;
use LWP::ConsoleLogger::Easy 0.000013 qw( debug_ua );
use Moo;
use MooX::HandlesVia;
use MooX::Options;
use MooX::StrictConstructor;
use Pithub::PullRequests;
use Text::SimpleTable::AutoWidth;
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Str );
use WWW::Mechanize::Cached;

with 'MooseX::Getopt::Dashes';

option debug_useragent => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Print a _lot_ of debugging info about LWP requests',
);

my $token_help = <<'EOF';
https://help.github.com/articles/creating-an-access-token-for-command-line-use for instructions on how to get your own GitHub access token
EOF

option cache_requests => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Try to cache GET requests',
);

option github_token => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    documentation => $token_help,
);

option github_user => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    documentation => 'The username of your GitHub account',
);

has _report => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    init_arg    => undef,
    handles     => { _repository_for_url => 'get', _report_urls => 'keys', },
    lazy        => 1,
    builder     => '_build_report',
);

has _github_client => (
    is      => 'ro',
    isa     => InstanceOf ['Pithub::PullRequests'],
    lazy    => 1,
    builder => '_build_github_client'
);

has _mech => (
    is      => 'ro',
    isa     => InstanceOf ['WWW::Mechanize'],
    lazy    => 1,
    builder => '_build_mech',
);

option url => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has _percent_formatter => (
    is      => 'ro',
    isa     => InstanceOf ['CLDR::Number::Format::Percent'],
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

    debug_ua( $mech, 7 ) if $self->debug_useragent;
    return $mech;
}

sub _build_report {
    my $self = shift;

    my %report;

    foreach my $url ( @{ $self->url } ) {
        my $repo = GitHub::MergeVelocity::Repository->new(
            github_client => $self->_github_client,
            url           => $url,
        );
        $report{$url} = $repo;
    }
    return \%report;
}

# workaround for init_arg being ignored
# https://rt.cpan.org/Ticket/Display.html?id=97849

sub report {
    my $self = shift;
    return $self->_report;
}

sub print_report {
    my $self = shift;

    my $table = Text::SimpleTable::AutoWidth->new;
    my @cols  = (
        'user',   'repo',       'velocity', 'PRs',
        'merged', 'merge days', 'closed',   'close days',
        'open',   'open days',
    );
    $table->captions( \@cols );

    my @repos = map { $self->_repository_for_url($_) } $self->_report_urls;

    foreach my $repository (
        sort { $b->report->average_velocity <=> $a->report->average_velocity }
        @repos
        )
    {
        my $report = $repository->report;
        $table->row(
            $repository->user,
            $repository->name,
            $report->average_velocity,
            $report->pull_request_count,
            map { $self->_columns_for_state( $report, $_ ) }
                ( 'merged', 'closed', 'open' ),
        );
    }

    binmode( STDOUT, ':encoding(UTF-8)' );
    print $table->draw;
    return;
}

sub _columns_for_state {
    my $self   = shift;
    my $report = shift;
    my $state  = shift;
    my $age    = $state . '_age';

    return (
        $report->$state
        ? sprintf( '%s (%i)',
            $self->_format_percent( $report->percentage_in_state($state) ),
            $report->$state )
        : 0,
        $report->$age ? sprintf( '%s/PR (%i)',
            $report->average_age_for_state($state),
            $report->$age ) : 0,
    );
}

1;

__END__

# ABSTRACT: Determine how quickly your pull request might get merged

=pod

=head1 SYNOPSIS

    use strict;
    use warnings;

    use GitHub::MergeVelocity;

    my $velocity = GitHub::MergeVelocity->new(
        url => [
            'https://github.com/neilbowers/PAUSE-Permissions',
            'https://github.com/oalders/html-restrict',
        ]
    );

    my $report = $velocity->report;

    $velocity->print_report; # prints a tabular report

=head1 CAVEATS

This module cannot (yet) distinguish between pull requests which were closed
because they were rejected and pull requests which were closed because the
patches were applied outside of GitHub's merge mechanism.

=cut
