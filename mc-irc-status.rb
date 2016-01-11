#!/usr/bin/env ruby
# coding: utf-8
require 'irconnect'
require 'pty'

JOIN_RE = /:\s(?<nick>\S+)\s+joined the game\s*$/i
PART_RE = /:\s(?<nick>\S+)\s+left the game\s*$/i
MSG_RE  = /INFO\]:\s<(?<nick>\S+)>\s(?<message>.+)\s*$/i

def connect_to_irc(server, channel, nick)
  connection = IRConnect::Connection.new(server, {nick: nick})
  connection.login(nick, 'mc-log-bot', 'example.com', 'MC Log Bot v0.0.1')
  connection.join_channel('#'+channel)
  return connection
end

def minecraft_main_loop(jar_file, channel, connection)

  PTY.spawn(format('java -Xmx1024M -Xms1024M -jar %s nogui', jar_file)) do |read, write, pid|
     Thread.new do
       loop do
           c = connection.receive
           if c.command == 'PRIVMSG'
             write.puts(format('say <%s> %s', c.sender, c.params[1..-1].join(' :')))
           end
       end
     end

     Thread.new do
       loop do
         line = read.readline
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

     loop do
       line = $stdin.readline
       write.puts(line)
     end
  end
end


connection = connect_to_irc(ARGV[1], ARGV[2], ARGV[3])
minecraft_main_loop(ARGV[0], ARGV[2], connection)
