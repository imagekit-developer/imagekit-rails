# Contributing to ImageKit Rails

First off, thank you for considering contributing to ImageKit Rails! It's people like you that make ImageKit Rails such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps which reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed after following the steps
* Explain which behavior you expected to see instead and why
* Include Ruby version, Rails version, and gem version

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Ruby style guide
* Include thoughtfully-worded, well-structured RSpec tests
* Document new code
* End all files with a newline

## Development Setup

1. Fork and clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Run the tests:
   ```bash
   bundle exec rspec
   ```
4. Run RuboCop:
   ```bash
   bundle exec rubocop
   ```

## Testing

* Write RSpec tests for new features
* Ensure all tests pass before submitting a PR
* Maintain or improve code coverage

## Style Guide

This project follows the Ruby Style Guide and uses RuboCop for enforcement.

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

## Documentation

* Update README.md with details of changes to the interface
* Update CHANGELOG.md following the Keep a Changelog format
* Add examples for new features

## Release Process

Maintainers will handle releases. The process includes:

1. Update version in `lib/imagekit/rails/version.rb`
2. Update CHANGELOG.md
3. Commit changes
4. Create a git tag
5. Push to RubyGems

Thank you for contributing! 🎉
