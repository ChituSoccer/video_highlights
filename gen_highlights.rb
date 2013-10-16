#!/usr/bin/ruby

# cut video with ffmpeg
# ./ffmpeg -ss 88 -t 5 -i VID_20131013_142935.mp4 -strict -2 o.mp4

# install ffmpeg on mac
# http://www.renevolution.com/how-to-install-ffmpeg-on-mac-os-x/
# brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-libass --with-libvo-aacenc --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-opus --with-rtmpdump --with-schroedinger --with-speex --with-theora --with-tools

# http://ffmpeg.org/faq.html#How-can-I-concatenate-video-files
# ffmpeg -ss 10 -t 5 -i VID_20131013_142935.mp4 -acodec copy -vcodec copy o1.mp4
# ffmpeg -ss 19 -t 5 -i VID_20131013_142935.mp4 -acodec copy -vcodec copy o2.mp4
# ffmpeg -i o1.mp4 -qscale:v 1 io1.mpg
# ffmpeg -i o2.mp4 -qscale:v 1 io2.mpg
# ffmpeg -i concat:"io1.mpg|io2.mpg" -c copy all.mpg
# ffmpeg -i all.mpg -qscale:v 2 oo.mp4

# ruby gen_highlights.rb xx.mp4 time.txt out.mp4

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

def gen_mpg_highlights(src_video, txt_file, mpg_video)
  pairs = get_time_pairs(txt_file)
  seg_filenames = []
  pairs.each_with_index do |pair, index|
    outmp4 = File.join($tmp_folder, "#{index}.mp4")
    outmpg = File.join($tmp_folder, "#{index}.mpg")
    seg_filenames << outmpg
    cmd_str = "#{$ffmpeg} -ss #{pair[0]} -t #{pair[1] - pair[0] + 2} -i \"#{src_video}\" #{outmp4}"
    p cmd_str
    system(cmd_str) unless File.exists? outmp4
    cmd_str = "#{$ffmpeg} -i #{outmp4} -qscale:v 1 #{outmpg}"
    p cmd_str
    system(cmd_str) unless File.exists? outmpg
  end
  
  all_segs = seg_filenames.join('|')
  merge_cmd_str = "#{$ffmpeg} -i \"concat:#{all_segs}\" -c copy #{mpg_video}"
  p merge_cmd_str
  system(merge_cmd_str)
end

def gen_highlights(src_video, txt_file, dst_video)
  mpg_video = tmpmpg = dst_video[0..-4] + 'mpg'
  gen_mpg_highlights(src_video, txt_file, mpg_video)
  cmd_str = "#{$ffmpeg} -i #{tmpmpg} -qscale:v 1 #{dst_video}"
  p cmd_str
  system(cmd_str)
end

# <video_dir>/session<i>.mp4
# <txt_dir>/session<i>.mp4
# i = 1, ..., session_count
def gen_highlights_for_multi_sessions(session_count, video_dir, txt_dir, dst_video)
  mpg_videos = []
  seg_filenames = []
  k = 1
  (1..session_count).each do |i|
    src_video = File.join(video_dir, "session#{i}.mp4")
    txt_file = File.join(txt_dir, "session#{i}.txt")
    pairs = get_time_pairs(txt_file)
    pairs.each do |pair|
      outmp4 = File.join($tmp_folder, "#{k}.mp4")
      outmpg = File.join($tmp_folder, "#{k}.mpg")
      seg_filenames << outmpg
      cmd_str = "#{$ffmpeg} -ss #{pair[0]} -t #{pair[1] - pair[0] + 2} -i \"#{src_video}\" #{outmp4}"
      p cmd_str
      system(cmd_str) unless File.exists? outmp4
      cmd_str = "#{$ffmpeg} -i #{outmp4} -qscale:v 1 #{outmpg}"
      p cmd_str
      system(cmd_str) unless File.exists? outmpg
      k = k + 1
    end
  end
  all_segs = seg_filenames.join('|')
  mpg_all = File.join($tmp_folder, 'all.mpg')
  cmd_str = "#{$ffmpeg} -i \"concat:#{all_segs}\" -c copy #{mpg_all}"
  p cmd_str
  system(cmd_str) unless File.exists? mpg_all
  cmd_str = "#{$ffmpeg} -i #{mpg_all} -qscale:v 1 #{dst_video}"
  p cmd_str
  system(cmd_str)
end

#if ARGV.size < 3
#  p 'ruby gen_highlights.rb xx.mp4 time.txt yy.mp4'
#  exit
#end

#gen_highlights(ARGV[0], ARGV[1], ARGV[2])
gen_highlights_for_multi_sessions(3, '../../Temp/2013-10-13-videos', '../../Temp/leon', 'leon.mp4')