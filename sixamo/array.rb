class Array
  def sum
    first, *rest = self
    rest.inject(first) { |r, v| r + v }
  end
end
