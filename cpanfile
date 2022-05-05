# This file is generated by Dist::Zilla::Plugin::CPANFile v6.024
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "CLDR::Number::Format::Percent" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::ISO8601" => "0";
requires "File::HomeDir" => "0";
requires "Math::Round" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "1.007000";
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
requires "perl" => "5.008";
requires "strict" => "0";
requires "warnings" => "0";
recommends "CHI" => "0";
recommends "LWP::ConsoleLogger" => "0.000013";
recommends "WWW::Mechanize::Cached" => "1.46";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "perl" => "5.008";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.008";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.71";
  requires "Code::TidyAll::Plugin::SortLines::Naturally" => "0.000003";
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.04";
  requires "Code::TidyAll::Plugin::UniqueLines" => "0.000003";
  requires "Parallel::ForkManager" => "1.19";
  requires "Perl::Critic" => "1.132";
  requires "Perl::Tidy" => "20180220";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Pod" => "1.41";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
  requires "Test::Vars" => "0.014";
  requires "Test::Version" => "1";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
