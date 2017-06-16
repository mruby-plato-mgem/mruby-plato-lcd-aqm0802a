module PlatoDevice
  class AQM0802A
    include Plato
    I2CADDR = 0x3e
    WIDTH   = 8
    HEIGHT  = 2
    @@init  = nil

    def initialize(addr=I2CADDR)
      @i2c = Plato::I2C.open(addr)
      setup unless @@init
      clear
    end

    # device independent

    def _clear
      @i2c.write(0, 0x01)
      Machine.delay 1
    end

    def _putc(c)
      @i2c.write(0x40, c[0])
    end

    def _locate(x, y)
      addr = 0x80 | ((y % HEIGHT) << 6) | (x % WIDTH)
      @i2c.write(0, addr)
    end

    def setup(params=nil)
      # wait 40ms
      Machine.delay 40

      # initialize sequence
      cmds = [
        0x38,   # Function set
        0x39,   # Function set
        0x14,   # Internal OSC frequency
        0x70,   # Contrast set
        0x56,   # Power/ICON/Contrast control
        0x6c,   # Follower control
        0x38,   # Function set
        0x0c    # Display ON/OFF control
      ].each {|cmd|
        @i2c.write(0, cmd)
        Machine.delay 1
      }

      @@init = true
    end

    # abstract (-> Plato::CharacterLCD)

    def clear
      _clear
      @x, @y = 0, 0
      self
    end

    def locate(x, y)
      @x = x % WIDTH
      @y = y % HEIGHT
      _locate(@x, @y)
      self
    end

    def putc(c)
      c = c.chr if c.instance_of?(Fixnum)
      _putc c[0]
      @x += 1
      if @x == WIDTH
        locate 0, (@y + 1) % HEIGHT
      end
    end

    def print(s)
      s.to_s unless s.instance_of?(String)
      s.each_char {|c| putc c}
    end

    def puts(s)
      print s
      (WIDTH - @x).times {putc ' '} if @x > 0
    end
  end
end
