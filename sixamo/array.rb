class Array
  def sum
    first, *rest = self

    rest.inject(first) do |r, v|
      r + v
    end
  end
end
