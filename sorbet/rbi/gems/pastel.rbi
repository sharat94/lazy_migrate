# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/pastel/all/pastel.rbi
#
# pastel-0.8.0

module Pastel
  def new(enabled: nil, eachline: nil); end
  def self.new(enabled: nil, eachline: nil); end
end
class Pastel::AliasImporter
  def color; end
  def env; end
  def import; end
  def initialize(color, env, output = nil); end
  def output; end
end
module Pastel::ANSI
  def background?(code); end
  def foreground?(code); end
  def self.background?(code); end
  def self.foreground?(code); end
  def self.style?(code); end
  def style?(code); end
end
class Pastel::Color
  def ==(other); end
  def alias_color(alias_name, *colors); end
  def apply_codes(string, ansi_colors); end
  def blank?(value); end
  def clear; end
  def code(*colors); end
  def colored?(string); end
  def decorate(string, *colors); end
  def disable!; end
  def eachline; end
  def enabled; end
  def enabled?; end
  def eql?(other); end
  def hash; end
  def initialize(enabled: nil, eachline: nil); end
  def inspect; end
  def lookup(*colors); end
  def strip(*strings); end
  def style_names; end
  def styles; end
  def valid?(*colors); end
  def validate(*colors); end
  include Pastel::ANSI
end
class Pastel::Detached
  def ==(other); end
  def [](*args); end
  def call(*args); end
  def eql?(other); end
  def hash; end
  def initialize(color, *styles); end
  def inspect; end
  def styles; end
  def to_proc; end
end
class Pastel::ColorResolver
  def color; end
  def initialize(color); end
  def resolve(base, unprocessed_string); end
end
class Pastel::ColorParser
  def self.attribute_name(ansi); end
  def self.color_name(ansi_code); end
  def self.parse(text); end
  def self.unpack_ansi(ansi_stack); end
  include Pastel::ANSI
end
class Pastel::DecoratorChain
  def ==(other); end
  def add(decorator); end
  def decorators; end
  def each(&block); end
  def eql?(other); end
  def hash; end
  def initialize(decorators = nil); end
  def inspect; end
  def self.empty; end
  include Enumerable
end
class Pastel::Delegator
  def ==(other); end
  def alias_color(*args, &block); end
  def chain; end
  def colored?(*args, &block); end
  def decorate(*args, &block); end
  def enabled?(*args, &block); end
  def eql?(other); end
  def evaluate_block(&block); end
  def hash; end
  def initialize(resolver, chain); end
  def inspect; end
  def lookup(*args, &block); end
  def method_missing(method_name, *args, &block); end
  def parse(*args, &block); end
  def resolver; end
  def respond_to_missing?(name, include_all = nil); end
  def self.wrap(resolver, chain = nil); end
  def strip(*args, &block); end
  def styles(*args, &block); end
  def to_s; end
  def undecorate(*args, &block); end
  def valid?(*args, &block); end
  extend Forwardable
end
class Pastel::InvalidAttributeNameError < ArgumentError
end
class Pastel::InvalidAliasNameError < ArgumentError
end