package GitHub::MergeVelocity;

use strict;
use warnings;
use feature qw( say );

use CHI;
use CLDR::Number::Format::Percent;
use GitHub::MergeVelocity::Repository;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use Moose;
use MooseX::Getopt::Dashes;
use MooseX::StrictConstructor;
use Pithub::PullRequests;
use Text::SimpleTable::AutoWidth;
use Types::Standard qw( ArrayRef Bool HashRef Str );
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
for instructions on how to get your own GitHub access token.
EOF

has cache_requests => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Try to cache GET requests',
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
    documentation => 'The username of your GitHub account',
);

has url => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has report => (
    is       => 'ro',
    isa      => HashRef,
    traits   => ['Hash'],
    init_arg => undef,
    handles  => { _repository_for_url => 'get', _report_urls => 'keys', },
    lazy     => 1,
    builder  => '_build_report',
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

has url => (
    is     => 'ro',
    isa    => ArrayRef,
    traits => ['Array'],

    #    handles => { '_all_repositories' => 'elements' },
    required => 1,
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

    debug_ua($mech) if $self->debug_useragent;
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

sub print_report {
    my $self = shift;

    my $table = Text::SimpleTable::AutoWidth->new;
    my @cols  = (
        'user',           'repo', 'PRs',           'merged',
        'avg merge days', 'open', 'avg open days', 'closed',
        'avg close days'
    );
    $table->captions( \@cols );

    foreach my $url ( sort $self->_report_urls ) {
        my $repository = $self->_repository_for_url($url);
        my $report     = $repository->report;
        $table->row(
            $repository->user,
            $repository->name,
            $repository->report->pull_request_count,
            $self->_format_percent( $report->percentage_in_state('merged') ),
            $report->average_age_for_state('merged'),
            $self->_format_percent( $report->percentage_in_state('open') ),
            $report->average_age_for_state('open'),
            $self->_format_percent( $report->percentage_in_state('closed') ),
            $report->average_age_for_state('closed'),
        );
    }

    binmode( STDOUT, ':utf8' );
    print $table->draw;
    return;
}

__PACKAGE__->meta->make_immutable();
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