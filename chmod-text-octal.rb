#! /usr/bin/ruby
require "chmod-translator"
require "chmod-translator-application"
ChmodTranslatorApplication.run {ChmodTranslator.from_text ARGV[0]}
