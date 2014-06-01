require 'thor'
require 'desktop'

module Desktop
  class CLI < Thor
    desc 'set IMAGE_PATH', 'Set all desktops to the image at IMAGE_PATH'
    long_desc <<-LONGDESC
      `desktop set` will set the desktop image of all spaces on all monitors to
      the image at `IMAGE_PATH`.

      > $ desktop set /path/to/image.png

      `IMAGE_PATH` can be a local file path or a URL.

      > $ desktop set http://url.to/image.jpg
    LONGDESC
    option :default_image_path, :hide => true
    option :skip_reload, :type => :boolean, :hide => true
    def set(path, already_failed = false)
      osx = OSX.new(options[:default_image_path], options[:skip_reload])
      image = HTTP.uri?(path) ? WebImage.new(path) : LocalImage.new(path)

      begin
        osx.desktop_image = image
      rescue OSX::DesktopImagePermissionsError => e
        if already_failed
          puts
          print "Sorry, but I was unable to change your desktop image. "
          puts  "Please create an issue if you think this is my fault:"
          puts
          puts  "https://github.com/chrishunt/desktop/issues/new"
          puts
          puts  "Here's the error:"
          puts
          puts  e.message
          fail
        else
          print "It looks like this is the first time you've tried to change "
          puts  "your desktop."
          puts
          print "We need to make your desktop image writable before we can "
          puts  "change it. This only needs to be done once."
          puts
          puts  "$ #{OSX.chown_command}"
          puts  "$ #{OSX.chmod_command}"
          puts
          osx.update_desktop_image_permissions

          set path, true
        end
      end
    end
  end
end
