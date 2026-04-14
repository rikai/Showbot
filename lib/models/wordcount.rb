# wordcount.rb
#
# Model that tracks the number of times a word appears across all shows.

require 'stopwords'

class WordCount < ActiveRecord::Base
  validates :word, presence: true, uniqueness: true

  def add_one
    increment!(:frequency)
  end

  def idf
    WordCount.count_document_frequency if IdfTracker.count == 0
    Math.log(IdfTracker.first.document_count.to_f / frequency)
  end

  # ------------------
  # Class Methods
  # ------------------

  def self.count_document_frequency
    if IdfTracker.count == 0
      suggestion_sets = Suggestion.group_by_show(Suggestion.order(created_at: :desc))
      IdfTracker.create(
        last_suggestion_time: Suggestion.last.created_at,
        last_suggestion_show: Suggestion.last.show
      )
      IdfTracker.first.update(document_count: suggestion_sets.count)
    else
      from = IdfTracker.first.last_suggestion_time
      suggestion_sets = Suggestion.group_by_show(
        Suggestion.where('created_at > ?', from).order(created_at: :desc)
      )
      return if suggestion_sets.count == 0

      first_new_suggestion = Suggestion.where('created_at > ?', from).first
      new_suggestions = Suggestion.where('created_at > ?', from)
      if IdfTracker.first.last_suggestion_show == first_new_suggestion.show &&
         (IdfTracker.first.last_suggestion_time - first_new_suggestion.created_at) > 0.75
        IdfTracker.first.update(
          document_count: IdfTracker.first.document_count + suggestion_sets.count - 1,
          last_suggestion_show: new_suggestions.last.show,
          last_suggestion_time: new_suggestions.last.created_at
        )
      else
        IdfTracker.first.update(
          document_count: IdfTracker.first.document_count + suggestion_sets.count,
          last_suggestion_show: new_suggestions.last.show,
          last_suggestion_time: new_suggestions.last.created_at
        )
      end
    end

    my_stop_words = WordCount.stop_words

    suggestion_sets.each do |set|
      word_list = []
      set.suggestions.each { |suggestion| word_list += tokenize(suggestion.title.downcase) }
      word_list = word_list.uniq - my_stop_words
      word_list.each { |word| WordCount.find_or_create_by(word: word).add_one }
    end
  end

  def self.stop_words
    sw = Stopwords::STOP_WORDS.dup
    sw.push("'s", "n't", "'ll", "'re", "'d", "'ve", "'m", ".", "!", "?", ",", "*", "...", "(", ")", "&", "``", "''", ":")
  end

  def self.generate_clouds(suggestion_sets)
    WordCount.count_document_frequency

    all_clouds_data = Array.new
    stop_words = WordCount.stop_words

    suggestion_sets.each do |set|
      set_counts = Hash.new(0)
      set_tfidf = Hash.new(0)

      set.suggestions.each do |suggestion|
        words = tokenize(suggestion.title.downcase) - stop_words
        words.each { |w| set_counts[w] += 1 }
      end

      set_counts.each { |w, tf| set_tfidf[w] = tf * WordCount.find_by(word: w).idf }

      max_val = set_tfidf.values.max
      this_cloud_data = Array.new
      set_tfidf.sort_by { |k, v| -v }.each { |k, v| this_cloud_data.push({ key: k, value: v / max_val }) }
      all_clouds_data.push({ show: set.suggestions.first.show, time: set.suggestions.first.created_at, data: this_cloud_data[0..249] })
    end

    all_clouds_data
  end
end

def tokenize(str)
  # Normalize all whitespace
  str.gsub!(/\s+/, ' ')

  # Fix curly quotes
  trans = { "\u2018" => "`",
    "\u2019" => "'",
    "\u201c" => "``",
    "\u201d" => "''",
  }
  trans_re = trans.keys.join('')
  str.gsub!(/([#{trans_re}])/) { " " + trans[$1] + " " }

  # Attempt to get correct directional quotes
  str.gsub!(/\"\b/, ' `` ')
  str.gsub!(/\b\"/, " '' ")
  str.gsub!(/\"(?=\s)/, " '' ")
  str.gsub!(/\"/, ' `` ')

  # Isolate all ellipses
  str.gsub!(/\.\.\./, ' ... ')

  # Isolate any embedded punctuation chars
  str.gsub!(/([,;:\@\#\$\%&])/, ' \1 ')

  # Assume sentence tokenization has been done first, so split FINAL periods only
  str.gsub!(/ ([^.]) \.  ([\]\)\}\>\"\']*) [ \t]* $ /x, '\1 .\2')

  # However, we may as well split ALL question marks and exclamation points,
  # since they shouldn't have the abbrev-marker ambiguity problem
  str.gsub!(/([?!])/, ' \1 ')

  # parentheses, brackets, etc.
  str.gsub!(/([\]\[\(\)\{\}\<\>])/, ' \1 ')

  str.gsub!(/(-{2,})/, ' \1 ')

  str.gsub!(/$/, ' ')
  str.gsub!(/^/, ' ')

  # possessive or close-single-quote
  str.gsub!(/\([^\']\)\' /, '\1 \' ')

  # as in it's, I'm, we'd
  str.gsub!(/\'([smd]) /i, ' \'\1 ')

  str.gsub!(/\'(ll|re|ve) /i, ' \'\1 ')
  str.gsub!(/n\'t /i, ' n\'t ')

  str.gsub!(/ (can)(not) /i, ' \1 \2 ')
  str.gsub!(/ (d\')(ye) /i, ' \1 \2 ')
  str.gsub!(/ (gim)(me) /i, ' \1 \2 ')
  str.gsub!(/ (gon)(na) /i, ' \1 \2 ')
  str.gsub!(/ (got)(ta) /i, ' \1 \2 ')
  str.gsub!(/ (lem)(me) /i, ' \1 \2 ')
  str.gsub!(/ (more)(\'n) /i, ' \1 \2 ')
  str.gsub!(/ (\'t)(is|was) /i, ' \1 \2 ')
  str.gsub!(/ (wan)(na) /i, ' \1 \2 ')

  str.split(' ')
end
