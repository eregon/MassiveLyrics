# The MIT License
# 
# Copyright (c) 2009 Davide Candiloro 
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'nokogiri'
require 'appscript'
require 'curb'

selected = Appscript.app('iTunes').selection.get

updated = 0
not_found = 0
already_there = 0

for a in selected
  lyrics, artist, title = [:lyrics, :artist, :name].map { |e| a.send(e).get }
  if lyrics.empty? and !artist.empty? and !title.empty?
      url = "http://lyrics.wikia.com/"
      song = "#{artist.downcase}:#{title.downcase}"

      #song.gsub!(/^[a-z]|\s+[a-z']/) { |letter| letter.upcase }
      song.gsub!(/\'\s/,' ')
      song.gsub!(/\s+/,'_')
      song.gsub!(/^[a-z]|_+[a-z]|[:\(\)\[\]][a-z]|/) { |letter| letter.upcase }
      song.gsub!(/&/, 'And' )
      
      puts song
 
      url += song

      c = Curl::Easy.perform(url)      
      pagecontent = c.body_str.gsub!(/&/, 'And' )
      doc = Nokogiri::HTML c.body_str
 
      ln = doc.css('div.lyricbox').first
      
      if ln == nil
        puts "CANNOT FIND any lyrics for " + artist + " - " + title
        not_found += 1
      else
        lyr = ln.to_s
                 
        lyr.gsub!(/<\/*\s*br\s*\/*>/, "\n") #STRIP brs
        lyr.gsub!(/<\/*\s*p\s*\/*>/, "\n") #STRIP p
        lyr.gsub!(/\<\s*(.*?)(\s*\>)/m, "") #STRIP any tag
        lyr.gsub!(/And#(\d+);/) { |n| $1.to_i.chr(Encoding::UTF_8) }
        lyr.strip!
        lyr.gsub!(/\s*Send .+? Ringtone to your Cell\s*/m, '')

        a.lyrics.set(lyr)
        puts "UPDATED lyrics for " + artist + " - " + title
        updated += 1
      end
  else 
    already_there += 1
  end
end

puts "==============================================================="
puts "lyrics already present for " + already_there.to_s  + " song(s)"
puts "lyrics not found for " + not_found.to_s + " song(s)"
puts "updated " + updated.to_s + " song(s)"
puts "==============================================================="
