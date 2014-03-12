#!/usr/bin/perl
use strict;

# Space Chase 
# 1/2014

use SDL; 
use SDL::Video;
use SDLx::App;
use SDL::Surface;
use SDL::Rect;
use SDL::Image;
use SDL::Event;
use SDL::Mouse;
use SDLx::Text;

# constants 
use constant bottomLimit=>750;
use constant screenWidth => 600;
use constant screenHeight => 800;
use constant some_basic_value => 50;
# for testing:
use constant canDie => 0;
# max number of random asteroids
use constant maxRocks => 2;

my ($app, $background, $backgroundRect, $event, $filename, $goodguy, $goodguyRect, $goodguyX, $goodguyY);
my ($granularity, $goodguyX_min, $goodguyX_max, $goodguyY_min, $goodguyY_max);
my ($cover);
my ($coverRect, $old_x);
my ($goodguyMaster);
my ($objectRect, $objectStart, $objectMaster);
my ($object, $objectImage, @allobjects);
my ($old_ship_x, $old_ship_y);
my ($new_badguy_rect);
my ($score);

# A location box for the text
my ($textbox);
  $textbox = SDLx::Text->new(size=>'25', # font can also be specified
                            color=>[255,0,0], # [R,G,B]
                            x =>50,
                            y=> 200);
###################################################################                            
$goodguyX = 200;
$goodguyY = 500;
# Min & Max for the X co-ordinates 
$goodguyX_min = 0;
$goodguyX_max = 540;
# sets the speed for the space ship
$granularity = 30;
# Min & Max for the Y co-ordinates
$goodguyY_min = 0;
$goodguyY_max = 720;


# First create a new App
$app = SDLx::App->new(
    title  => "Space Chase",
    width  => screenWidth, # use same width as background image
    height => screenHeight, # use same height as background image
    depth  => 16, 
    exit_on_quit => 1 # Enable 'X' button
);

# Event handlers
$app->add_event_handler(\&quit_event);
$app->add_event_handler(\&key_event);
# Move handlers
$app->add_move_handler(\&collisions);
$app->add_move_handler(\&moveBadGuys);
# Show handlers
$app->add_show_handler(\&showBadGuys);
$app->add_show_handler(\&showGoodGuy);


# Set up the background image + rectangle
$filename = "background.png";
$background = SDL::Image::load( $filename);
$cover = $background;
$backgroundRect = SDL::Rect->new(0,0,$background->w,$background->h);

# The good guy
$filename = "spaceship04.png";
$goodguy = SDL::Image::load( $filename);
# make master recatngle for later copying
$goodguyMaster = SDL::Rect->new(0,0,$goodguy->w,$goodguy->h);

# The image that will be falling down 
$filename = "asteroid04.png";
# Load asteroids
$objectImage = SDL::Image::load( $filename);

# The asteroids location
$objectMaster = SDL::Rect->new(0,0, $objectImage->w,$objectImage->h);

# loop to create random asteroids
for (my $i=0; $i<maxRocks; $i++) {
  $object={};
  $object->{image}=$objectImage;
  $object->{x}= randStartRockX();
  $object->{y} = randStartRockY();
  $object->{rect}=0;
  push @allobjects, $object;
}

$score=1000;
$textbox->write_to($app,"$score");
my $y=0;
foreach my $thing (@allobjects) {
  $thing->{rect} = SDL::Rect->new($thing->{x}, $thing->{y}, $thing->{image}->w, $thing->{image}->h);
}


$goodguyRect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
SDL::Video::blit_surface( $background, $backgroundRect, $app, $backgroundRect );
SDL::Video::blit_surface ( $goodguy, $goodguyMaster, $app, $goodguyRect);
SDL::Video::blit_surface ( $object, $objectMaster, $app, $objectRect);
SDL::Video::update_rects( $app, $goodguyRect, $backgroundRect);

# set key repeat on after 50ms, then every 5ms
SDL::Events::enable_key_repeat(50, 5);

# Start the game loop
$app->run;

############################################################ SUBROUTINES #########################################################################

sub quit_event {
  my ($event, $app) = @_;
	if($event->type == SDL_QUIT) {
    $app->stop;
  }
}

sub key_event {
  my ($event, $app) = @_;
  my $key_name = SDL::Events::get_key_name( $event->key_sym );  
  my ( $new_ship_rect, $coverRect);
  $old_ship_y = $goodguyY;
  $old_ship_x = $goodguyX;
  if (($key_name eq "x") || ($key_name eq "X") ) {
    $app->stop;
  }
  elsif ($key_name eq "up") {
    $goodguyY -=$granularity;
    if ($goodguyY < $goodguyY_min) {
      $goodguyY = $goodguyY_min;
    }
  }
  elsif ($key_name eq "down") {
    $goodguyY +=$granularity;
    if ($goodguyY > $goodguyY_max) {
      $goodguyY = $goodguyY_max;
    }
  }
  elsif ($key_name eq "left") {  
    $goodguyX -=$granularity;
    if ($goodguyX < $goodguyX_min) {
      $goodguyX = $goodguyX_min;
    }
  }
  elsif ($key_name eq "right") {
    $goodguyX +=$granularity;
    if ($goodguyX > $goodguyX_max) {
      $goodguyX = $goodguyX_max;
    }
  }
}

sub moveBadGuys {
  my ($step, $app, $t) = @_;
  foreach my $thing (@allobjects) {
  # 288 sets speed for the asteriod
    $thing->{y} += 5;
    if ($thing->{y} > bottomLimit) {
      $thing->{y} = randStartRockY();
      $thing->{x} = randStartRockX();
    }
  }
}

sub showBadGuys {
  my ($delta, $app) = @_;
  foreach my $thing (@allobjects) {
    my ($badguy_x, $badguy_y) = ($thing->{x}, $thing->{y});
    my ($old_rock_x, $old_rock_y) = ($thing->{old_rock_x},$thing->{old_rock_y} );
    my $object = $thing->{image};
    if (($badguy_x != $old_rock_x) || ($badguy_y != $old_rock_y)) {
      $new_badguy_rect = SDL::Rect->new($badguy_x,$badguy_y,$object->w,$object->h);
      #$coverRect = SDL::Rect->new($old_rock_x, $old_rock_y, $object->w, $object->h);
      #SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );
      SDL::Video::blit_surface( $object, $objectMaster, $app, $new_badguy_rect);
      SDL::Video::update_rects( $app, $new_badguy_rect);
      $app->sync();
    }
  }
}

sub showGoodGuy {
  my ($delta, $app) = @_;
  my ($new_ship_rect, $coverRect);
  #print "[$goodguyY][$old_ship_y]\n";
  $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
  SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );    
  $coverRect = SDL::Rect->new($old_ship_x, $old_ship_y, $goodguy->w, $goodguy->h);
  SDL::Video::blit_surface ( $goodguy, $goodguyMaster, $app, $new_ship_rect);
  SDL::Video::update_rects( $app,  $coverRect, $new_ship_rect);
}

sub randStartRockX {
  return int(rand(screenWidth-5))+5;
}

sub randStartRockY {
  my $y=int(rand(200));
  return (0-$y);
}

sub collisions {
  my ($step, $app, $t) = @_;
  my ($objectcenterX, $objectcenterY);
  foreach my $thing (@allobjects) {
    my ($objectX, $objectY) = ($thing->{x}, $thing->{y});
    # Using formula for distance between two points
    my $distance = sqrt (($objectX - $goodguyX)**2 + ($objectY - $goodguyY)**2);
    $distance=int($distance);
    if (($distance < some_basic_value) && (canDie)) {
      print "You've been hit!\n";
      SDL::Video::blit_surface( $background, $backgroundRect, $app, $backgroundRect);
      $app->stop;
      }
  }
}
