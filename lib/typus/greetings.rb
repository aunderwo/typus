module Typus

  @@greetings = { "Hala" => "Arabic", 
                  "G'day" => "Australian", 
                  "Hello" => "English", 
                  "Tere" => "Estonian", 
                  "Salut" => "French", 
                  "Yasou" => "Greek", 
                  "Aloha" => "Hawaiian", 
                  "Góðan daginn" => "Icelandic", 
                  "Konnichiwa" => "Japanese", 
                  "Bangawoyo" => "Korean", 
                  "Ni hao" => "Mandarin", 
                  "Hola" => "Spanish", 
                  "Hej" => "Swedish", 
                  "Kumusta" => "Tagalog", 
                  "Moyo" => "Tshiluba", 
                  "Merhaba" => "Turkish", 
                  "Sawubona" => "Zulu" }.to_a

  mattr_accessor :greetings

end