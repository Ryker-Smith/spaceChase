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

my ($app, $background, $backgroundRect, $event, $filename, $goodguy, $goodguyRect, $goodguyX, $goodguyY);
my ($granularity, $goodguyX_min, $goodguyX_max, $goodguyY_min, $goodguyY_max) = (5, 0, 750, 0, 550, 3);
my ($cover);
my ($coverRect, $old_x);
my ($goodguymaster);
my ($objectRect, $objectStart, $objectmaster);
my ($objectX, $objectY);

$goodguyX = 200;
$goodguyY = 300;
# Min & Max for the X co-ordinates 
$goodguyX_min = -225;
$goodguyX_max = 310;
# sets the speed for the space ship
$granularity = 10;
# Min & Max for the Y co-ordinates
$goodguyY_min = -200;
$goodguyY_max = 425;

# First create a new App
$app = SDLx::App->new(
    title  => "Space Chase",
    width  => 600, # use same width as background image
    height => 800, # use same height as background image
    depth  => 16, 
    exit_on_quit => 1 # Enable 'X' button
);

$app->add_event_handler( \&quit_event);
$app->add_event_handler( \&key_event);

# Set up the background image + rectangle
$filename = "background.png";
$background = SDL::Image::load( $filename);
$cover = $background;
$backgroundRect = SDL::Rect->new(0,0,$background->w,$background->h);

#  The good guy
$filename = "spaceship03.png";
$goodguy = SDL::Image::load( $filename);
# make master recatngle for later copying
$goodguymaster = SDL::Rect->new(0,0,$goodguy->w,$goodguy->h);
# now do the actual start for the g-g

# The image that will be falling down 
my ($object);
$filename = "asteroid03.png";
$object = SDL::Image::load( $filename);
$objectmaster = SDL::Rect->new(0,0,$object->w,$object->h);
$objectX = 400;
$objectY = 200;

# $object={};
# $object->{image}=$objectStart;
# $object->{x}=200;
# $object->{y}=300;

$goodguyRect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h,);

SDL::Video::blit_surface( $background, $backgroundRect, $app, $backgroundRect );
SDL::Video::blit_surface ( $goodguy, $goodguymaster, $app, $goodguyRect);
SDL::Video::blit_surface ( $object, $objectmaster, $app, $objectRect);
SDL::Video::update_rects( $app, $goodguyRect, $backgroundRect);

# set key repeat on after 100ms, then every 0ms
SDL::Events::enable_key_repeat(100, 1);

# Start the game loop
$app->run;

sub quit_event {
  my ($event, $app) = @_;
	if($event->type == SDL_QUIT) {
    $app->stop;
  }
}

sub key_event {
  my ($event, $app) = @_;
  my $key_name = SDL::Events::get_key_name( $event->key_sym );  
  my ($old_ship_x, $old_ship_y, $new_ship_rect, $coverRect);
  if (($key_name eq "x") || ($key_name eq "X") ) {
    $app->stop;
  }
  elsif ($key_name eq "up") {
    $old_ship_y = $goodguyY;
    $goodguyY -=$granularity;
    if ($goodguyY < $goodguyY_min) {
      $goodguyY = $goodguyY_min;
    }
    $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
    $coverRect = SDL::Rect->new($goodguyX, $old_ship_y, $goodguy->w, $goodguy->h);
    SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );    
    SDL::Video::blit_surface ( $goodguy, $goodguymaster, $app, $new_ship_rect);
    SDL::Video::update_rects( $app,  $coverRect, $new_ship_rect);
  }
  elsif ($key_name eq "down") {
    $old_ship_y = $goodguyY;
    $goodguyY +=$granularity;
    if ($goodguyY > $goodguyY_max) {
      $goodguyY = $goodguyY_max;
    }
    $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
    $coverRect = SDL::Rect->new($goodguyX, $old_ship_y, $goodguy->w, $goodguy->h);
    SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );    
    SDL::Video::blit_surface ( $goodguy, $goodguymaster, $app, $new_ship_rect);
    SDL::Video::update_rects( $app,  $coverRect, $new_ship_rect);
  }
  elsif ($key_name eq "left") {
    $old_ship_x = $goodguyX;
    $goodguyX -=$granularity;
    if ($goodguyX < $goodguyX_min) {
    
      $goodguyX = $goodguyX_min;
    }
    $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
    $coverRect = SDL::Rect->new($old_ship_x, $goodguyY, $goodguy->w, $goodguy->h);
    SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );    
    SDL::Video::blit_surface ( $goodguy, $goodguymaster, $app, $new_ship_rect);
    SDL::Video::update_rects( $app, $coverRect, $new_ship_rect);
  }
  elsif ($key_name eq "right") {
    $old_ship_x = $goodguyX;
    $goodguyX +=$granularity;
    if ($goodguyX > $goodguyX_max) {
      $goodguyX = $goodguyX_max;
    }
    $new_ship_rect = SDL::Rect->new($goodguyX,$goodguyY,$goodguy->w,$goodguy->h);
    $coverRect = SDL::Rect->new($old_ship_x, $goodguyY, $goodguy->w, $goodguy->h);
    SDL::Video::blit_surface( $cover, $coverRect, $app, $coverRect );    
    SDL::Video::blit_surface ( $goodguy, $goodguymaster, $app, $new_ship_rect);
    SDL::Video::update_rects( $app,  $coverRect, $new_ship_rect);
  }
}

