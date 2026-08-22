# Guard::Kitchen

[![Gem Version](https://badge.fury.io/rb/guard-kitchen.svg)](https://badge.fury.io/rb/guard-kitchen)

Uses test-kitchen to help you develop Chef cookbooks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'guard-kitchen'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install guard-kitchen
```

## Usage

From within a cookbook:

```bash
guard init kitchen
```

## Development

Install the dependencies and run the test suite:

```bash
bundle install
bundle exec rake test
```

The suite is RSpec, lives under `spec/`, and runs entirely offline — every
`kitchen` invocation is stubbed, so nothing spins up a VM. It uses
[guard-compat](https://github.com/guard/guard-compat) to exercise the plugin
and its bundled Guardfile template without booting Guard itself, and enforces
line and branch coverage thresholds through SimpleCov.

To run a single file or example:

```bash
bundle exec rspec spec/unit/guard/kitchen_spec.rb
bundle exec rspec spec/unit/guard/kitchen_spec.rb:42
```

Style is checked with Cookstyle:

```bash
bundle exec cookstyle --chefstyle
```

### Documentation

The public API is documented with [YARD](https://yardoc.org). Generate it into
`doc/` with:

```bash
bundle exec rake doc
```

The task lists anything still undocumented. It is intentionally kept out of the
default task and out of CI — missing docs should never fail a build.

## Status

This software project is no longer under active development as it has no active maintainers. The software may continue to work for some or all use cases, but issues filed in GitHub will most likely not be triaged. If a new maintainer is interested in working on this project please come chat with us in #test-kitchen on Chef Community Slack.

## License

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

