#!/bin/sh
cat lib/Github/MergeVelocity/PullRequest.pm > bin/script.pl
cat lib/Github/MergeVelocity/Types.pm >> bin/script.pl
cat lib/Github/MergeVelocity.pm >> bin/script.pl

echo "

package main;

use strict;
use warnings;

use Github::MergeVelocity;

Github::MergeVelocity->new_with_options->print_report;

" >> bin/script.pl
