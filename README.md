# Guard::Kitchen

[![Gem Version](https://badge.fury.io/rb/guard-kitchen.svg)](https://badge.fury.io/rb/guard-kitchen)

A [Guard](https://github.com/guard/guard) plugin that runs
[Test Kitchen](https://github.com/test-kitchen/test-kitchen) for you while you work
on a Chef cookbook.

Instead of switching to a terminal and typing `kitchen converge` or `kitchen verify`
after every edit, you leave `guard` running in a window. It builds your instances
when it starts, reruns the right kitchen command each time you save a file, and
tears the instances down when you quit.

## Requirements

Before installing this gem you need:

- **Ruby 3.1 or later.**
- **Test Kitchen**, plus a driver such as `kitchen-vagrant` or `kitchen-dokken`.
  This gem shells out to the `kitchen` command and does not install it for you, so
  `kitchen --version` must work from your shell first.
- **A cookbook with a `kitchen.yml`.** Test Kitchen needs at least one suite and
  platform defined. See the
  [Test Kitchen documentation](https://kitchen.ci/) if you have not written one yet.

If you have [Chef Workstation](https://www.chef.io/products/chef-workstation)
installed you already have Test Kitchen and a driver.

## Installation

Add the gem to your cookbook's `Gemfile`:

```ruby
gem "guard-kitchen"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install guard-kitchen
```

## Quick start

From the root of your cookbook:

```bash
guard init kitchen
```

That writes a `Guardfile` in the current directory — or appends to the one already
there — telling Guard which files this plugin should watch. Then start Guard:

```bash
guard
```

Guard creates your Test Kitchen instances and waits. Edit a recipe or a test, save,
and watch it react. Press `Ctrl-C` to quit, which destroys the instances again.

Because a first `kitchen create` can take a while, expect the initial start to be
slow. Output from every kitchen command is streamed straight to your terminal as it
runs, so you can follow a long converge rather than waiting in silence.

## What happens as you work

Guard drives the plugin through a small lifecycle:

| When | guard-kitchen runs |
| --- | --- |
| Guard starts | `kitchen create` |
| You save a watched file | `kitchen converge` or `kitchen verify` — see below |
| You press `Enter` at the Guard prompt | `kitchen verify`, covering every suite |
| You type `r` and press `Enter` | `kitchen destroy`, then `kitchen create` |
| You quit Guard | `kitchen destroy` |

Which command a save triggers depends on what you changed:

- **A file under `test/integration/<suite>/`** only affects that suite, so only that
  suite is verified. Saving `test/integration/default/bats/foo.bats` runs
  `kitchen verify '(default)-.+' -p`. If a single save touches several suites, all of
  them go into that one pattern.
- **Anything else** — a recipe, an attribute, a template, a file, a provider, a
  resource — could affect every suite, so the whole cookbook is converged with
  `kitchen converge`.

When a kitchen command fails, the plugin sends a failure notification and tells Guard
the task failed. Guard reports it and keeps running, so a broken converge does not end
your session — fix the file, save again, and it retries. Successes and failures both
go through Guard's notifier, so you get desktop notifications if you have one
configured.

Every kitchen command is given a three hour timeout, which is generous enough that a
slow converge over a slow network will not be cut short.

## The Guardfile it writes

`guard init kitchen` adds this block:

```ruby
guard "kitchen" do
  watch(%r{test/.+})
  watch(%r{^recipes/(.+)\.rb$})
  watch(%r{^attributes/(.+)\.rb$})
  watch(%r{^files/(.+)})
  watch(%r{^templates/(.+)})
  watch(%r{^providers/(.+)\.rb})
  watch(%r{^resources/(.+)\.rb})
end
```

It is a normal Guardfile, so edit it freely. Add a `watch` line if your cookbook keeps
code somewhere else, or remove one if a directory changes too often to be worth
reacting to. Guard's own
[Guardfile documentation](https://github.com/guard/guard#readme) covers the syntax.

Note that `metadata.rb` is deliberately not watched: changing it on its own does not
change what a converge produces.

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
