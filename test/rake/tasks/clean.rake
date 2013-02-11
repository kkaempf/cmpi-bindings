require 'rake/clean'
CLEAN.include("**/*~", "Gemfile.lock", "doc", ".yardoc", "pkg",
"generated", "tmp", "samples/provider/*.rdoc",
"samples/provider/*.registration")
