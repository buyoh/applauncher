#!/bin/bash

set -eu

bundle exec rubocop --auto-correct
bundle exec rspec
