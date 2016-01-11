#!/usr/bin/env ruby
# coding: utf-8
require 'irconnect'
require 'file-tail'

JOIN_RE = /:\s(?<nick>\S+)\s+joined the game\s*$/i
PART_RE = /:\s(?<nick>\S+)\s+left the game\s*$/i
MSG_RE  = /INFO\]:\s<(?<nick>\S+)>\s(?<message>.+)\s*$/i

def connect_to_irc(server, channel, nick)
  connection = IRConnect::Connection.new(server, {nick: nick})
  connection.login(nick, 'mc-log-bot', 'example.com', 'MC Log Bot v0.0.1')
  connection.join_channel('#'+channel)
  return connection
end

def pong_irc_connection(connection)
  loop do
    connection.receive
  end
end

def minecraft_log_reader(filename, channel, connection)
  File.open(filename) do |log|
    log.extend(File::Tail)
    log.interval = 1
    log.backward(1)
    log.tail do |line|
      puts(line)
      if (match = JOIN_RE.match(line))
        connection.privmsg('#' + channel, format('%s logget inn på MC', match['nick']))
      elsif (match = PART_RE.match(line))
        connection.privmsg('#' + channel, format('%s logget ut fra MC', match['nick']))
      elsif (match = MSG_RE.match(line))
        connection.privmsg('#' + channel, format('<%s> %s', match['nick'], match['message']))
      end
    end
  end
end

connection = connect_to_irc(ARGV[1], ARGV[2], ARGV[3])
Thread.new do
  pong_irc_connection(connection)
end
minecraft_log_reader(ARGV[0], ARGV[2], connection)
