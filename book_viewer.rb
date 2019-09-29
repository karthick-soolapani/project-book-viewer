require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @contents = File.readlines('data/toc.txt', chomp: true)
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, idx|
      "<p id=p#{idx + 1}>#{paragraph}</p>"
    end.join
  end

  def highlight_matches(text, term)
    text.gsub(/(#{term})/i, '<strong>\1</strong>')
  end
end

def each_chapter
  @contents.each_with_index do |chap_name, idx|
    chap_num = idx + 1
    chap_contents = File.read("data/chp#{chap_num}.txt")
    yield chap_name, chap_num, chap_contents
  end
end

def matching_contents(search_string)
  result = []

  return result if search_string.nil? || search_string.strip.empty?

  each_chapter do |chap_name, chap_num, chap_contents|
    paragraphs = chap_contents.split("\n\n")
    matched_paragraphs = {}

    paragraphs.each.with_index do |paragraph, idx|
      next unless paragraph.downcase.include?(search_string.downcase)
      matched_paragraphs[idx + 1] = paragraph
    end

    next if matched_paragraphs.empty?
    result << {name: chap_name, number: chap_num, paragraphs: matched_paragraphs}
  end

  result
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  chap_num = params[:number].to_i
  chap_name = @contents[chap_num - 1]

  not_found unless (1..@contents.size).cover? chap_num

  @title = "Chapter #{chap_num}: #{chap_name}"
  @chapter = File.read("data/chp#{chap_num}.txt")

  erb :chapter
end

get "/search" do
  @search_string = params[:query]
  @matched_contents = matching_contents(@search_string)

  erb :search
end

not_found do
  redirect "/"
end
