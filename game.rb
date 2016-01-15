require 'gosu'

class GameWindow < Gosu::Window

  attr_reader :score
  attr_reader :blip_sound
  attr_reader :explosion_sound

  def initialize
    super 640, 480
    self.caption = "Pong"

    margin = 20

    @player = Paddle.new( margin, margin )
    @last_mouse_y = margin

    @enemy = Paddle.new( self.width - Paddle::WIDTH - margin, margin)

    @ball = Ball.new( 100, 100, { :x => 4, :y => 4 } )

    @score = [0, 0]
    @font = Gosu::Font.new(20)
    @flash = {}
    @counter = 0
    load_sounds
  end

  def button_down(id)
    case id
    when Gosu::KbEscape
      close
    end
  end

  def update
    player_move
    ai_move

    @ball.update

    if @ball.collide?(@player)
      # play sound
      @ball.reflect_horizontal
      @blip_sound.play
      increase_speed
    elsif @ball.collide?(@enemy)
      # play sound
      @ball.reflect_horizontal
      @blip_sound.play
      increase_speed
    elsif @ball.x <= 0
      @ball.x = @player.right
      score[1] += 1
      @ball.v[:x] = 4
      flash_side(:left)
      @explosion_sound.play
    elsif @ball.right >= self.width
      @ball.x = @enemy.left
      score[0] += 1
      @ball.v[:x] = -4
      flash_side(:right)
      @explosion_sound.play
    end

    @ball.reflect_vertical if @ball.y < 0 || @ball.bottom > self.height
  end

  def increase_speed
    @ball.v[:x] = @ball.v[:x] * 1.1
  end

  def player_move
    y = mouse_y
    diff = y - @last_mouse_y
    @player.y += diff

    @player.y = 0 if @player.y <= 0
    @player.bottom = self.height if @player.bottom >= self.height

    @last_mouse_y = y

  end

  def ai_move
    pct_move = 0
    distance = @enemy.center_x - @ball.center_x
    if distance > self.width / 3
      pct_move = 0.05
    elsif distance > self.width / 2
      pct_move = 0.1
    else
      pct_move = 0.14
    end

    diff = @ball.center_y - @enemy.center_y
    @enemy.y += diff * pct_move

    @enemy.top = 0 if @enemy.top <= 0
    @enemy.bottom = self.height if @enemy.bottom >= self.height
  end

  def flash_side(side)
    @flash[side] = true
  end

  def draw
    draw_background

    if @flash[:left]
      Gosu.draw_rect 0, 0, self.width / 2, self.height, Gosu::Color::RED
      @flash[:left] = nil
    end

    if @flash[:right]
      Gosu.draw_rect self.width / 2, 0, self.width, self.height, Gosu::Color::RED
      @flash[:right] = nil
    end

    draw_center_line
    draw_score
    @player.draw
    @enemy.draw
    @ball.draw
  end

  def draw_background
    Gosu.draw_rect 0, 0, self.width, self.height, Gosu::Color::BLACK
  end

  def draw_center_line
    center_x = self.width / 2
    segment_length = 10
    gap = 5
    color = Gosu::Color::GREEN
    y = 0
    begin
      draw_line center_x, y, color,
                center_x, y + segment_length, color
      y += segment_length + gap
    end while y < self.height
  end

  def draw_score
    center_x = self.width / 2
    offset = 15
    char_width = 10
    z_order = 100
    @font.draw score[0].to_s, center_x - offset - char_width, offset, z_order
    @font.draw score[1].to_s, center_x + offset, offset, z_order
  end

  def load_sounds
    path = File.expand_path(File.dirname(__FILE__))
    @blip_sound = Gosu::Sample.new(File.join(path, "blip.wav"))
    @explosion_sound = Gosu::Sample.new(File.join(path, "explosion.wav"))
  end
end

class GameObject
  attr_accessor :x
  attr_accessor :y
  attr_accessor :w
  attr_accessor :h

  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def left
    x
  end

  def right
    x + w
  end

  def right=(r)
    self.x = r - w
  end

  def top
    y
  end

  def top=(t)
    self.y = t
  end

  def bottom
    y + h
  end

  def center_y
    y + h/2
  end

  def center_x
    x + x/2
  end

  def bottom=(b)
    self.y = b - h
  end

  def collide?(other)
    x_overlap = [0, [right, other.right].min - [left, other.left].max].max
    y_overlap = [0, [bottom, other.bottom].min - [top, other.top].max].max
    x_overlap * y_overlap != 0
  end
end

class Ball < GameObject
  WIDTH = 5
  HEIGHT = 5

  attr_reader :v
  def initialize(x, y, v)
    super(x, y, WIDTH, HEIGHT)
    @v = v
  end

  def update
    self.x += v[:x]
    self.y += v[:y]
  end

  def reflect_horizontal
    v[:x] = -v[:x]
  end

  def reflect_vertical
    v[:y] = -v[:y]
  end

  def draw
    Gosu.draw_rect x, y, WIDTH, HEIGHT, Gosu::Color::RED
  end
end

class Paddle < GameObject
  WIDTH = 12
  HEIGHT = 60

  def initialize(x, y)
    super(x, y, WIDTH, HEIGHT)
  end

  def draw
    Gosu.draw_rect x, y, w, h, Gosu::Color.argb(0xff_ffffff)
  end
end

window = GameWindow.new
window.show
