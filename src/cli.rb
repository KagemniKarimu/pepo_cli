# frozen_string_literal: true

require 'erb'
print '.'
require 'tty-prompt'
print '.'
require 'tty-table'
print '.'
require 'tty-progressbar'
print '.'
require 'tty-font'
print '.'
require 'tty-tree'
print '.'
require 'tty-reader'
print '.'
require 'tty-link'
print '.'
require 'socket'
print '.'
require 'httparty'
print '.'
require 'rubygems/text'
print '.'
require 'soundplayer'
print '.'
require 'dentaku'
print '.'
require_relative 'os'
print '.'
require_relative 'cmd'
print '.'
require_relative 'amiri'
print '.'
require '../api/filebase_helper'
print '.'
require '../api/sia_stats_info'
print '.'

puts 'dependencies initialized!'

PROGRAM_BUILD = 'MAPEMA'
PROGRAM_VERSION = '0.0.1'
PROGRAM_DESC = 'a multi-functional command-line utility for the Sia-Skynet ecosystem'
SOCKET_IP = Socket.ip_address_list[1].ip_address

# CommandLineInterface handles all user's inputs and displays output
class PepoCommandLine
  attr_reader :font, :style, :cmd_cursor, :prompt
  attr_accessor :valid_commands, :filebase_instances, :macros, :commenting

  include HTTParty
  include OS
  include Gem::Text
  include Amiri

  # All of Pepo_CLI's defaults are set in the Initialize Method of the Interface
  def initialize
    @font = TTY::Font.new(:straight)
    @style = Pastel.new
    @prompt = TTY::Prompt.new(interrupt: proc { program_close })
    @set_ip = SOCKET_IP
    @cmd_cursor = default_cursor
    @suggestion_sensitivity = default_sensitivity
    @sound = default_volume
    @valid_commands = []
    @macros = {}
    @variables = {}
    @filebase_instances = []
    @calc = Dentaku::Calculator.new
  end

  def default_cursor
    "#{@style.blue.bold('>')}#{@style.white.bold('>')} "
  end

  def default_sensitivity
    3
  end

  def default_volume
    false
  end

  def interface_header
    print @style.bright_blue.bold(@font.write('PEPO'))
    puts @style.italic(PROGRAM_VERSION), @style.inverse(PROGRAM_DESC)
    puts "                                                   #{@online}@#{@set_ip}"
  end

  def main_menu
    choices = %w[CLI Help About Exit]
    user_selection = @prompt.select('', choices, filter: true)
    case user_selection
    when 'CLI' then command_loop
    when 'Help' then program_help
    when 'About' then program_about
    when 'Exit' then program_close
    end
  end

  def program_start
    sound(:start)
    display_online
    clear_screen
    main_menu
  end

  def program_close
    sound(:close)
    @prompt.say 'Kwa Heri'
    clear_screen(return_home: false)
    exit
  end

  def program_help
    help = ERB.new(File.read('./msg/help.txt'))
    puts "#{help.result}\n\n\n"
    menu_escape_hatch
  end

  def program_about
    about = ERB.new(File.read('./msg/about.txt'))
    puts "#{about.result}\n\n\n"
    menu_escape_hatch
  end

  def menu_escape_hatch
    if @prompt.keypress(@style.bright_white.on_blue('Press any key to return to main menu'))
      clear_screen
      main_menu
    end
  end

  def command_loop
    break_words = %w[quit exit stop acha]
    loop do
      user_input = @prompt.ask(@cmd_cursor)
      break if break_words.include?(user_input)

      if macro?(user_input) then process_macro(user_input)
      else
        process_command(user_input); end
    end
    program_close
  end

  def process_macro(macro)
    macros[macro].each do |action|
      action.strip!
      if action.chars.first == '#'
        prompt.say("#{@cmd_cursor} #{@style.green(action)}")
        sound(:bump)
      elsif macro?(action.split(" ").first)
        process_macro(action)
      else
        process_command(action)
      end
    end
  end

  def sound(type)
    case type
    when :start then Sound.play('../snd/bump.wav', 2)
    when :close then Sound.play('../snd/exit.wav', 3) if sound?
    else Sound.play("../snd/#{type}.wav") if sound?
    end
  end

  def clear_screen(return_home: true)
    system 'cls' if OS.windows?
    system 'clear' unless OS.windows?
    interface_header if return_home
  end

  def ping(address)
    # HardCoded to do Only 4 Pings
    return error 'unable to conduct ping from offline mode' unless internet_access?
    system "ping #{address}" if OS.windows?
    system "ping -c 4 #{address}" unless OS.windows?
  end

  def dir(directory)
    system "dir #{directory}" if OS.windows?
    system "ls #{directory}" unless OS.windows?
  end

  def internet_access?
    true if HTTParty.get('https://www.icann.org/')
  rescue SocketError
    error 'Offline Mode Activated'
    false
  end

  def sound?
    @sound
  end

  def print_ip_addresses(host = nil)
    if host.nil?
      Socket.ip_address_list.each_with_index do |socket_entry, num|
        print "IP#{num}:  "
        @prompt.say(@style.cyan(socket_entry.ip_address.to_s))
      end
    else
      get_ip_address(host)
    end
  end

  def set_ip_address
    @set_ip = HTTParty.get('https://api64.ipify.org')
    @prompt.say("Set to #{@style.black.on_white(@set_ip)}")
  rescue SocketError => e
    error(e.message)
    @set_ip = SOCKET_IP
  end

  def display_online
    @online = internet_access? ? @style.green('ONLINE') : @style.red.dim('OFFLINE')
  end

  def suggestion_match?(input, cmd, suggestion_num)
    chars_input = input.chars.sort
    chars_cmd = cmd.chars.sort
    difference = levenshtein_distance(cmd, input)
    chars_input == chars_cmd || difference < suggestion_num
  end

  def adjust_sensitivity(num = nil)
    e_msg = 'pick a number from 0..10'
    return error(e_msg) unless num.nil? || (0..10).to_a.map(&:to_s).include?(num)

    original = @suggestion_sensitivity
    num.nil? ? sensitivity_slider(original) : toggle_sensitivity(num.to_i)
    unless original == @suggestion_sensitivity
      @prompt.say("#{@style.black.on_white('Sensitivity')} adjusted from #{original} to #{@suggestion_sensitivity}")
    end
  end

  def sensitivity_slider(default)
    @suggestion_sensitivity = @prompt.slider('Suggestion Sensitivity', max: 10, step: 1, default: default)
  end

  def toggle_sensitivity(num)
    @suggestion_sensitivity = num
  end

  def adjust_sound(on_off = nil)
    e_msg = 'please select on/off'
    return error(e_msg) unless on_off.nil? || %w[on off ON OFF].include?(on_off)

    on_off.nil? ? sound_slider : toggle_sound(on_off)
  end

  def toggle_sound(on_off)
    @sound = (on_off =~ /^on$/i)
    state = @style.green(on_off.upcase)
    @prompt.say("Program Sound #{state}")
  end

  def sound_slider
    status = @sound ? 'ON' : 'OFF'
    status = @prompt.slider('Program Sound', %w[OFF ON], default: status)
    @sound = status == 'ON'
  end

  def parse_input(input)
    parsed = {}
    splitted = input.to_s.strip.split(' ')
    parsed[:command] = splitted.first&.downcase
    parsed[:arguments] = splitted.drop(1)
    parsed
  end

  def process_command(input)
    input = parse_input(input)
    cmd_input = input[:command]
    args_in = input[:arguments]

    if valid_command?(cmd_input)
      amri = valid_commands.detect { |cmd| cmd.name_arr.include?(cmd_input) }
      amri.execute(*args_in)
      sound(:success)
    elsif cmd_input.nil? || cmd_input.chars.first == '#'
      sound(:bump)
    else
      invalid_command(input[:command])
      sound(:error)
    end
  end

  def invalid_command(command_input)
    matches = []
    # stylized_cmd = @style.underline(command_input)
    # styled_msg = @style.black.on_white('Invalid Command')
    @prompt.say('Invalid Command')

    valid_command_names.each do |cmd|
      matches.push(cmd) if suggestion_match?(command_input, cmd, @suggestion_sensitivity)
    end
    macro_names.each do |mac|
      matches.push(mac) if suggestion_match?(command_input, mac, @suggestion_sensitivity)
    end

    @prompt.say("Did you mean #{matches} ?") unless matches.empty?
  end

  def error(message = nil)
    sound(:error)
    @prompt.error(message) if message
  end

  def success(message = nil)
    sound(:success)
    @prompt.ok(message) if message
  end

  def calculate(*input)
    calculation = @calc.evaluate(input.join(" "))
    calculation ? @prompt.say(calculation) : @prompt.error('unable to evaluate given expressions')
  end

  def store(var_name, value)
    return error 'please use non-numeric characters for your variable name' if var_name.chars.all?{'1234567890-=+/.*'.include?(_1)}
    return error 'please start all variable names with $' unless var_name.start_with?('$')
    # return unless Float(value) != nil

    variable = @calc.store(var_name, value)
    variable ? @prompt.say(variable.memory) : @prompt.error('unable to create variable')
  end

  def set_macro(phrase, *actions)
    overwrite = true
    return error "Reserved word, #{phrase}" if valid_command?(phrase)

    overwrite = @prompt.yes?("`#{phrase}` already exists. Do you want to overwrite `#{phrase}` ?") if macro?(phrase)
    return unless overwrite

    if actions.empty?
      macro_actions = @prompt.multiline(macro_instructions)
      @macros[phrase] = macro_actions; @prompt.say "Macro #{phrase} has been created."
    elsif actions
      macro_actions = actions.join(' ').split(';')
      @macros[phrase] = macro_actions; @prompt.say "Macro #{phrase} has been created."
    end

  end

  def macro_instructions
    'Type in specific command-line commands/actions for macro to execute.
Each line may only have one command. You cannot edit a line further once you press RETURN.
Any previous instructions for a same-name macro will be overwritten instead of appended.'
  end

  def macro?(input)
    @macros.include?(input)
  end

  def macro_names
    @macros.keys
  end

  def valid_command_names
    valid_commands.flat_map(&:name_arr)
  end

  def valid_command?(input)
    valid_command_names.include?(input)
  end

  def reinitialize
    @filebase_instances.clear
    @macros.clear
    @suggestion_sensitivity = default_sensitivity
    @sound = default_volume
    @cmd_cursor = default_cursor
    sound(:startup)
    display_online
    set_ip_address
    clear_screen
    main_menu
  end

  def import_macro (file_path, permission=nil)
    return error 'invalid path, please use an absolute file path' unless File.absolute_path?(file_path)
    return error 'use ! as the final argument to grant permission' if permission&.is_a?(String) && permission != '!'

    force = (permission == '!') if permission

    case
    when File.directory?(file_path)
      return error 'unable to find directory' unless Dir.exist?(file_path)

      pep_files = Dir.entries(file_path).select { _1.end_with?('.pep') }.map { "#{file_path}/#{_1}" }
      unless force
        permission = @prompt.yes? ("There are #{pep_files.length} macros in the given directory. Import all?")
      end
      pep_files.each { |file| load_macro_from_file(file,force) } if (force || permission)
    when File.file?(file_path)
      return error "cannot find file... #{file_path}" unless File.exist?(file_path)

      permission = @prompt.yes? ("Are you sure you want to load this macro?") unless force
      load_macro_from_file(file_path,force) if permission || force
    else
      error 'invalid path, unable to resolve file/directory'
    end

  end


  def load_macro_from_file(file_path, force, overwrite: true)
    macro_name = File.basename(file_path, File.extname(file_path))

    if macro?(macro_name) && !force
      overwrite = @prompt.yes? "macro '#{macro_name}' already exists. would you like to overwrite?"
    end
    return unless overwrite

    macro_actions = []
    File.readlines(file_path, chomp: true).each do |action|
      macro_actions << action
    end
    @macros[macro_name] = macro_actions
    success "macro '#{macro_name}' successfully loaded into memory."
  rescue Errno::ENOENT
    error "unable to load macro from #{file_path}"
  end

  def list_macros
    @prompt.say(macro_names.join(' '))
  end

  def get_macro(macro)
    return error 'macro not detected' unless macro?(macro)
    script = colorize_macro(@macros[macro]).join("\n")
    @prompt.say(script)
  end

  def colorize_macro(actions)
    actions.map do |line|
      broken_line = line.split(' ')
      first_word = broken_line.first
      plain_line = broken_line.drop(1).join(' ')
      if valid_command?(first_word&.downcase)
        "#{@style.bright_white.italic(first_word)} #{plain_line}"
      elsif macro?(first_word)
        "#{@style.bright_cyan.italic(first_word)} #{plain_line}"
      elsif first_word&.start_with?('#')
        @style.black.on_green(line)
      else
        @style.bright_red.strikethrough(line)
      end
    end
  end

  def export_macro(write_path, *macros)
    return error "invalid path: #{write_path}. Please specify a valid path." unless Dir.exist?(write_path)
    
    permission = macros.last == '!' ? true : nil
    if macros&.length.positive? && !macros.all?{ _1 == '!' }
      macros = @macros.select { macros.include?(_1) }
      permission ||= @prompt.yes?("There are #{macros.length} matching macros! Are you sure you want to write to file(s)?")
    else
      macros = @macros
      permission ||= @prompt.yes?("There are #{@style.blue.on_white(@macros.length)} loaded macros. Are you sure you want to write to #{@style.black.on_white(write_path)}?")
    end

    write_macros_to_file(macros, write_path) if permission
  end

  def write_macros_to_file(macros, write_path)
    macros.each do |macro|
      macro_name = macro[0]; macro_script = macro[1]
      abs_write_path = File.join(write_path, "#{macro_name}.pep")
      if File.write(abs_write_path, macro_script.join("\n")).positive?
        success "Written #{macro_name}.pep to #{write_path}"
      else
        error "Unable to write #{macro_name}"
      end
    end
  rescue Errno::EACCES
    @prompt.error "write permission to #{write_path} denied"
  end

  def delete_macro(macro, permission=false)
    permission ||= @prompt.yes?("Are you sure you would like to delete #{macro}?")
    return error 'use ! as the final argument to grant permission' if permission&.is_a?(String) && permission != '!'
    return unless permission

    @macros.delete(macro) ? success("#{macro} was deleted.") : error("unable to find #{macro} . macros are case-sensitive.")
  end
  end



puts 'creating command instance...'
$command_instance = PepoCommandLine.new
