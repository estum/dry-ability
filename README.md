# Dry::Ability

Dry::Ability is an authorization library, which is trying to replace [cancancan](https://github.com/CanCanCommunity/cancancan) API. The goal is creating less secondary objects by performing authorization. Some codebase, like a controller extension, was copied from cancancan and slightly modified, but public API stays the same. By some reasons (especially, due to integration with InheritedResources) I forked it from version `1.17.0`.

One significant difference with CanCanCan is that an ability's rules a defined once on class definition and stored into `Dry::Container`.

Docs, specs & benchmarks is coming soon…


## Installation

Add this to your Gemfile:

    gem 'dry-ability'

and run the `bundle install` command.

## Getting Started

Soon…