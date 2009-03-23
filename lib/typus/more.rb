module Typus

  def self.to_sentence_options(connector = '&')
    { :words_connector => ', ', :last_word_connector => " #{connector} " }
  end

  def self.roles_sentence
    Typus::Configuration.roles.keys.sort.to_sentence(Typus.to_sentence_options('or'))
  end

end