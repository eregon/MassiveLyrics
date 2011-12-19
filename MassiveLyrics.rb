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
require 'open-uri'

LYRICS_WIKI = 'http://lyrics.wikia.com/'

selected = Appscript.app('iTunes').selection.get

updated = 0
not_found = 0
already_there = 0

BadLyrics = Class.new(StandardError)

selected.each do |a|
  lyrics, artist, title = [:lyrics, :artist, :name].map { |e| a.send(e).get }
  if lyrics.empty? and !artist.empty? and !title.empty?
      song = "#{artist}:#{title}"
      #song.gsub!(/^[a-z]|\s+[a-z']/) { |letter| letter.upcase }
      song.gsub!(/\'\s/, ' ')
      song.gsub!(/\s+/, '_')
      song.gsub!(/^[a-z]|_+[a-z]|[:\(\)\[\]][a-z]|/) { |letter| letter.upcase }
      song.gsub!(/&/, 'And')
      song.gsub!(/\?/, '%3F')

      puts song if $VERBOSE

      url = LYRICS_WIKI + song
      url = ARGV.first if $VERBOSE and ARGV.size == 1 and selected.size == 1

      begin
        doc = Nokogiri::HTML open url
        ln = doc.css('div.lyricbox').first
        lyr = ln.to_s

        lyr.gsub!(/<\/*\s*br\s*\/*>/, "\n") #STRIP brs
        lyr.gsub!(/<\/*\s*p\s*\/*>/, "\n") #STRIP p
        lyr.gsub!(/\<\s*(.*?)(\s*\>)/m, "") #STRIP any tag
        lyr.gsub!(/And#(\d+);/) { |n| $1.to_i.chr(Encoding::UTF_8) }
        lyr.strip!
        lyr.gsub!(/\s*Send .+? Ringtone to your Cell\s*/m, '')

        raise BadLyrics, 'empty lyrics' if lyr.empty?
        raise BadLyrics, 'not complete' if lyr.include? 'Unfortunately, we are not licensed to display the full lyrics for this song at the moment.'

        a.lyrics.set(lyr)
        puts "UPDATED lyrics for #{artist} - #{title}"
        updated += 1
      rescue OpenURI::HTTPError, BadLyrics
        puts "CANNOT FIND lyrics for #{artist} - #{title} (#{$!.inspect})"
        not_found += 1
      end
  else
    already_there += 1
  end
end

puts "==============================================================="
puts "lyrics already present for #{already_there} song(s)"
puts "lyrics not found for #{not_found} song(s)"
puts "updated #{updated} song(s)"
puts "==============================================================="
