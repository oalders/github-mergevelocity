#!/usr/bin/perl

use strict;
use warnings;

# PODNAME: github-mergevelocity.pl
# ABSTRACT: CLI for determining how quickly a pull request might get merged

use lib 'lib';

use Github::MergeVelocity;

Github::MergeVelocity->new_with_options->print_report;
