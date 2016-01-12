class Version
  include Comparable
  attr_reader :major, :minor, :patch

  def initialize(number)
    @major, @minor, @patch = number.split('.').map(&:to_i)
  rescue => e
    puts "Version with #{number}"
    puts e.inspect
  end

  def to_a
    [major, minor, patch].compact
  end

  def to_s
    [major, minor, patch].join('.')
  end

  def <=>(version)
    (major.to_i <=> version.major.to_i).nonzero? ||
    (minor.to_i <=> version.minor.to_i).nonzero? ||
    patch.to_i <=> version.patch.to_i
  end

  def matches?(operator, number)
    version = Version.new(number)
    self == version

    return self == version if operator == '='
    return self > version  if operator == '>'
    return self < version  if operator == '<'
    return version <= self && version.next > self if operator  == '~>'
  end

  def succ
    next_splits = to_a

    if next_splits.length == 1
      next_splits[0] += 1
    else
      next_splits[-2] += 1
      next_splits[-1] = 0
    end

    Version.new(next_splits.join('.'))
  end
end
#http://shorts.jeffkreeftmeijer.com/2014/compare-version-numbers-with-pessimistic-constraints/
