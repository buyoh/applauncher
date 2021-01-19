#!/bin/bash

set -eu

bundle exec typeprof src/launcher.rb -o src/launcher.rbs
bundle exec rubocop --auto-correct
bundle exec rspec
