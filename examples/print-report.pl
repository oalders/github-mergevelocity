use strict;
use warnings;

use GitHub::MergeVelocity;

my $mv = GitHub::MergeVelocity->new(
    url => [
        'https://github.com/neilbowers/PAUSE-Permissions',
        'https://github.com/oalders/html-restrict',
    ]
);

$mv->print_report;
