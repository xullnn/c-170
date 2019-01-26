
module BCrypt

  class Password < String
    attr_reader :checksum
    attr_reader :salt
    attr_reader :version
    attr_reader :cost

    class << self
      def create(secret, options = {})
        cost = options[:cost] || BCrypt::Engine.cost
        raise ArgumentError if cost > 31
        Password.new(BCrypt::Engine.hash_secret(secret, BCrypt::Engine.generate_salt(cost)))
      end

      def valid_hash?(h)
        h =~ /^\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}$/
      end
    end

    # Initializes a BCrypt::Password instance with the data from a stored hash.
    def initialize(raw_hash)
      if valid_hash?(raw_hash)
        self.replace(raw_hash)
        @version, @cost, @salt, @checksum = split_hash(self)
      else
        raise Errors::InvalidHash.new("invalid hash")
      end
    end

    # Compares a potential secret against the hash. Returns true if the secret is the original secret, false otherwise.
    def ==(secret)
      super(BCrypt::Engine.hash_secret(secret, @salt))
    end
    alias_method :is_password?, :==

  private

    # Returns true if +h+ is a valid hash.
    def valid_hash?(h)
      self.class.valid_hash?(h)
    end

    # call-seq:
    #   split_hash(raw_hash) -> version, cost, salt, hash
    #
    # Splits +h+ into version, cost, salt, and hash and returns them in that order.
    def split_hash(h)
      _, v, c, mash = h.split('$')
      return v.to_str, c.to_i, h[0, 29].to_str, mash[-31, 31].to_str
    end
  end

end
