package GitHub::MergeVelocity::Types;

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

__END__

# ABSTRACT: Custom types for use by GitHub::MergeVelocity modules
