puts <<-EOF

  This will generate a bunch of /awstats.*.conf files for all of
  the configured domains, and an /update_all.sh that you can use to
  analyse all domains (if you make it world-executable).

  It will also generate an /index.html which lists all of the
  domains configured.

  To run: call awstats_config(domains)

EOF

def awstats_config(domains, var_www)
  domains.each do |domain|
    filename = "awstats.#{domain}.conf"

    puts "--> Writing #{filename}..."

    File.open(filename, "w") do |file|
      file.write "# Generated by generate-config.rb, do not modify\n\n"

      content = File.read("awstats.conf")

      to_replace = {
        "LogFile" => "\"/usr/share/awstats/tools/logresolvemerge.pl /var/log/apache2/other_vhosts_access.log /var/log/apache2/other_vhosts_access.log.* |\"",
        "LogFormat" => "\"%virtualname %host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot\"",
        "SiteDomain" => "\"#{domain}\"",
        "HostAliases" => "\"www.#{domain} #{domain}:80 #{domain}:443 www.#{domain}:80 www.#{domain}:443\"",
      }

      to_replace.each do |key, value|
        content.gsub!(/^#{Regexp.quote(key)}=.+$/, "#{key}=#{value}")
      end

      file.write content

      file.write "\n\n"
      file.write "# Additional plugins to load\n"
      file.write "LoadPlugin=\"ipv6\"\n"

      puts " (#{content.length} bytes)"
    end
  end

  puts "--> Writing update_all.sh..."

  File.open("update_all.sh", "w") do |file|
    file.write "# Generated by generate-config.rb, do not modify\n\n"

    file.write "cp #{File.basename(__FILE__)}/index.html #{var_www}/index.html\n"

    domains.each do |domain|
      file.write "/usr/lib/cgi-bin/awstats.pl -config=#{domain} -update\n"
      file.write "/usr/share/awstats/tools/awstats_buildstaticpages.pl -config=#{domain} -dir=#{var_www}/ -awstatsprog=/usr/lib/cgi-bin/awstats.pl -showcorrupted\n"
      file.write "\n"
    end

    file.write "echo \"Complete!\"\n";
  end

  puts "--> Writing index.html..."

  File.open("index.html", "w") do |file|
    file.write "<html>"
    file.write "<h1>awstats</h1>"
    file.write "<ul>"

    domains.sort.each do |domain|
      file.write "<li><a href=\"awstats.#{domain}.html\">#{domain}</a></li>"
    end

    file.write "</ul>"
    file.write "</html>"
  end
end
