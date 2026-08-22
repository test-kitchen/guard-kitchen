# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Guard::Kitchen::VERSION` is now defined when you require the gem. It lived in
  `lib/guard/kitchen/version.rb` but nothing required it, so it was only
  available to the gemspec.
- `Guard::Kitchen::COMMAND_TIMEOUT`, the three hour timeout applied to every
  kitchen command, is now a named constant rather than a literal repeated at
  each call site.
- YARD documentation for the public API, and a `rake doc` task to generate it.
  Documentation is generated on demand and is not part of CI.

### Changed

- **Ruby 3.1 or later is now required.**
- Command output streams to `$stdout` rather than the `STDOUT` constant, so it
  follows a reassigned stdout.
- The five near-identical shell-out blocks behind `start`, `stop`, `run_all` and
  both branches of `run_on_changes` are now a single private method. Behaviour,
  including every message and notification, is unchanged.
- The README is rewritten for someone who has never used this gem. It now states
  the prerequisites (Ruby, Test Kitchen and a driver, a cookbook with a
  `kitchen.yml`), walks through a first run, and documents which kitchen command
  each kind of change triggers.
- Links point at `https` rather than `http`.

### Removed

- The README's Status section, which said the project was no longer under active
  development and had no active maintainers. The claim is not supported by the
  state of the repository.

### Fixed

- Cookstyle now lints the gemspec, `Gemfile` and `Rakefile`. They were excluded
  by an `AllCops/Include` list that only matched `**/*.rb`, so they were never
  checked.

### Internal

- Unit tests run against Ruby 3.1 through 4.0 in CI, and Cookstyle runs with the
  `--chefstyle` rules.
- The test suite was rewritten for RSpec 3: the removed `should_receive`/`stub`
  syntax is gone, verifying doubles are enabled, and the hand-rolled
  `Guard::Plugin` monkey patch is replaced by `guard-compat`. Coverage grew from
  10 examples to 47, with line coverage enforced by SimpleCov.

## [0.1.0]

- Initial release.

[Unreleased]: https://github.com/test-kitchen/guard-kitchen/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/test-kitchen/guard-kitchen/releases/tag/v0.1.0
