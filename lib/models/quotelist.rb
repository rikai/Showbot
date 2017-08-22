class QuoteList
  attr_reader :quotes, :can_save
  
  def initialize(quotes)
    quotes ||= Hash.new
    @quotes = quotes
  end

  # Returns a random quote by a person's name or alias;
  # otherwise, returns an empty string.
  # TODO(thefirstofthe300): this should probably be renamed for better semantics
  def quote_for(name)
    canonical_name = canonicalize name
    
    if !canonical_name
      return ''
    end
    
    @quotes[canonical_name][:quotes].sample
  end

  # Adds a quote to a person's quote array; otherwise, returns and empty string.
  #
  # This function will create the specified person if they don't already exist.
  def add(name, quote)
    name.downcase!
    
    @quotes[name] ||= {aliases:[], quotes:[]}
    
    if @quotes[name][:quotes].select {|q| q.downcase == quote.downcase}.length > 0
      return ""
    end
    
    @quotes[name][:quotes] << quote
  end

  # Deletes a quote from a person's quote array if they exist; otherwise,
  # returns an empty string.
  #
  # Note: if the specified person has no more quotes after the deletion, the
  # person object will be deleted, even if they still have aliases.
  def del(name, quote)
    canonical_name = canonicalize(name)
    
    if !canonical_name
      return ""
    end
    
    @quotes[canonical_name][:quotes].delete(quote)
    
    if @quotes[canonical_name][:quotes].length == 0
      @quotes.delete(canonical_name) 
    end
  end

  # Adds an alias to the specified person; returns, an empty string if the
  # person does not exist.
  def add_alias(name, a)
    canonical_name = canonicalize(name)
    
    if !canonical_name
      return ''
    end
    
    @quotes[canonical_name][:aliases] << a
  end

  # Deletes an alias for the specified person; returns, an empty string if the
  # person does not exist.
  def del_alias(name, a)
    canonical_name = canonicalize(name)
    
    if !canonical_name
      return '' 
    end
  
    @quotes[canonical_name][:aliases].delete(a)
  end

  # Gets the equivalent yaml for the quotes attribute
  # Used by the quotes plugin to write the data to file
  def get_yaml
    @quotes.to_yaml
  end

  private

  # Take the given name and return the name used to access information in the
  # quotes hash
  def canonicalize(name)
    name.downcase!

    @quotes.select do |canonical, value|
      match_canonical?(canonical, name) || in_aliases?(value[:aliases], name)
    end.keys.first
  end

  # Helper function used by canonicalize
  def match_canonical?(canonical, name)
    canonical == name
  end

  # Helper function used by canonicalize to match case-insensitively against the
  # given array of aliases
  def in_aliases?(aliases, name)
    Array(aliases).map(&:downcase).any? do |element|
      element.downcase == name
    end
  end
end
