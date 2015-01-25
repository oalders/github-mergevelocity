requires "CHI" => "0";
requires "CLDR::Number::Format::Percent" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "LWP::ConsoleLogger::Easy" => "0";
requires "Math::Round" => "0";
requires "Moose" => "0";
requires "MooseX::Getopt::Dashes" => "0";
requires "MooseX::StrictConstructor" => "0";
requires "Pithub::PullRequests" => "0";
requires "Text::SimpleTable::AutoWidth" => "0";
requires "Type::Library" => "0";
requires "Type::Utils" => "0";
requires "Types::Standard" => "0";
requires "WWW::Mechanize::Cached" => "0";
requires "feature" => "0";
requires "lib" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "DDP" => "0";
  requires "Test::Most" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};
