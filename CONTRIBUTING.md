# Contributing

## Setting up the environment

This repository contains a `.ruby-version` file, which should work with either [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://github.com/asdf-vm/asdf) with the [ruby plugin](https://github.com/asdf-vm/asdf-ruby).

Please follow the instructions for your preferred version manager to install the Ruby version specified in the `.ruby-version` file.

To set up the repository, run:

```bash
$ bundle install
```

This will install all the required dependencies.

## Using the repository from source

If you'd like to use the repository from source, you can either install from git or reference a cloned repository:

To install via git in your `Gemfile`:

```ruby
gem "imagekitio-rails", git: "https://www.github.com/imagekit-developer/imagekit-rails"
```

Alternatively, reference local copy of the repo:

```bash
$ git clone -- 'https://www.github.com/imagekit-developer/imagekit-rails' '<path-to-repo>'
```

```ruby
gem "imagekitio-rails", path: "<path-to-repo>"
```

## Running tests

```bash
$ ./scripts/test
```

Or:

```bash
$ bundle exec rake spec
```

Run specific test file:

```bash
$ bundle exec rspec spec/helper_spec.rb
```

Run specific test:

```bash
$ bundle exec rspec spec/helper_spec.rb:42
```

## Linting and formatting

This repository uses [rubocop](https://github.com/rubocop/rubocop) for linting and formatting.

To lint:

```bash
$ ./scripts/lint
```

Or:

```bash
$ bundle exec rake rubocop
```

To format and fix all lint issues automatically:

```bash
$ bundle exec rubocop -A
```

## Documentation

To generate documentation:

```bash
$ bundle exec yard doc
```

To preview documentation:

```bash
$ bundle exec yard server --reload --port 8808
```

Then open http://localhost:8808

## Submitting changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linter: `./scripts/test && ./scripts/lint`
5. Commit with a clear message
6. Push to your fork
7. Open a Pull Request
