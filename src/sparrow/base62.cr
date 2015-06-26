module Base62
  Keys = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  KeysHash = Keys.each_char.with_index.inject(Hash(Char, Int32).new) do |h, kv|
    h[kv[0]] = kv[1]
    h
  end
  Base = Keys.length

  # Encodes base10 (decimal) number to base62 string.
  def self.encode(num)
    return "0" if num == 0
    return nil if num < 0

    str = ""
    while num > 0
      # prepend base62 charaters
      str = Keys[num % Base].to_s + str
      num = num / Base
    end
    return str
  end

  # Decodes base62 string to a base10 (decimal) number.
  def self.decode(str)
    num = 0
    i = 0
    len = str.length - 1
    # while loop is faster than each_char or other 'idiomatic' way
    while i < str.length
      pow = Base ** (len - i)
      num += KeysHash[str[i]] * pow
      i += 1
    end
    return num
  end
end
