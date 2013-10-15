#!/usr/bin/ruby

# cut video with ffmpeg
# ./ffmpeg -ss 88 -t 5 -i VID_20131013_142935.mp4 -strict -2 o.mp4

# ruby gen_highlights.rb xx.mp4 time.txt out.mp4

# brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-libass --with-libvo-aacenc --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-opus --with-rtmpdump --with-schroedinger --with-speex --with-theora --with-tools

# extract <start_time, end_time> pairs from text file
# cut with ffmpeg

require 'fileutils'

$tmp_folder = 'tmp'
FileUtils.mkdir_p($tmp_folder)

$ffmpeg = 'ffmpeg'

# 1:33 -> 93
def get_seconds(str)
  ss = str.split(':')
  ss[0].to_i * 60 + ss[1].to_i
end

def get_time_pairs(txt_file)
  pairs = []
  File.open(txt_file, 'r') do |f|  
    while line = f.gets  
      puts line  
      ss = line.split(',')
      break if ss.size < 2
      start_time = get_seconds(ss[0])
      end_time = get_seconds(ss[1])
      pairs << [start_time, end_time]
    end  
  end  
  pairs
end

def gen_highlights(src_video, txt_file, dst_video)
  pairs = get_time_pairs(txt_file)
  seg_filenames = []
  pairs.each_with_index do |pair, index|
    outfile = File.join($tmp_folder, "#{index}.mp4")
    seg_filenames << outfile
    next if File.exists? outfile
    cmd_str = "#{$ffmpeg} -ss #{pair[0]} -t #{pair[1] - pair[0]} -i \"#{src_video}\" #{outfile}"
    p cmd_str
    system(cmd_str)
  end
  all_segs = seg_filenames.join('|')
  merge_cmd_str = "#{$ffmpeg} -i \"concat:#{all_segs}\" -c copy #{dst_video}"
  p merge_cmd_str
  system(merge_cmd_str)
end

if ARGV.size < 3
  p 'ruby gen_highlights.rb xx.mp4 time.txt yy.mp4'
  exit
end

gen_highlights(ARGV[0], ARGV[1], ARGV[2])