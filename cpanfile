requires "CLDR::Number::Format::Percent" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "File::HomeDir" => "0";
requires "Math::Round" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "0";
requires "MooX::HandlesVia" => "0";
requires "MooX::Options" => "0";
requires "MooX::StrictConstructor" => "0";
requires "Path::Tiny" => "0";
requires "Pithub::PullRequests" => "0";
requires "Text::SimpleTable::AutoWidth" => "0.09";
requires "Type::Library" => "0";
requires "Type::Utils" => "0";
requires "Types::Standard" => "0";
requires "URI" => "0";
requires "WWW::Mechanize::GZip" => "0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "CHI" => "0";
recommends "LWP::ConsoleLogger" => "0.000013";
recommends "WWW::Mechanize::Cached" => "1.46";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Test::Most" => "0";
  requires "Test::RequiresInternet" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};
