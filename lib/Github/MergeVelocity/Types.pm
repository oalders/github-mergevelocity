package Github::MergeVelocity::Types;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Type::Library -base, -declare => ( 'Datetime', 'Duration' );
use Type::Utils;
use Types::Standard -types;

class_type Datetime, { class => "DateTime" };
class_type Duration, { class => "DateTime::Duration" };

coerce Datetime, from Str,
    via { DateTime::Format::ISO8601->parse_datetime( $_ ) };
1;
