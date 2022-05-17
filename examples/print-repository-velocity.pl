use strict;
use warnings;

use GitHub::MergeVelocity;

my $mv = GitHub::MergeVelocity->new(
    url => [
        'neilbowers/PAUSE-Permissions',
        'https://github.com/oalders/html-restrict/issues',
    ]
);

my @repos = map { $mv->_repository_for_url($_) } $mv->_report_urls;
foreach my $repository (@repos) {
    my $report = $repository->report;
    print $repository->user . "/"
        . $repository->name . ": "
        . $report->average_velocity . "\n";
}

