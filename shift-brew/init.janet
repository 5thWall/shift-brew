(use jaylib)
(use junk-drawer)

(def black (map |(/ $ 255) [50 47 41]))
(def white (map |(/ $ 255) [177 174 168]))
(def screen-width 400)
(def screen-height 240)

(def GS (gamestate/init))

# Components
(def-component-alias position vector/from-named)
(def-component-alias velocity vector/from-named)
(def-component circle :radius :number :color (any))

# System Callbacks
(def-system sys-move
  {moveables [:position :velocity]}
  (each [pos vel] moveables
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

(def-system sys-draw-circle
  {circles [:position :circle]}
  (each [pos circle] circles
    (draw-circle
     (pos :x) (pos :y)
     (circle :radius) (circle :color))))

(gamestate/def-state
 pause
 :update (fn pause-update [self dt]
           (draw-poly [100 100] 5 40 0 :magenta)

           (when (key-pressed? :space)
             (:unpause-game GS))))

(gamestate/def-state
 game
 :world (create-world)
 :init (fn game-init [self]
         (let [world (get self :world)]
           # Entities
           (let [pos (position :x 100.0 :y 100.0)
                 vel (velocity :x 1 :y 2)
                 circ (circle :radius 40 :color white)]
             (add-entity world pos vel circ))

           (add-entity world
                       (position :x 200.0 :y 50.0)
                       (velocity :x -2 :y 4)
                       (circle :radius 40 :color white))

           # Systems
           (register-system (self :world) sys-move)
           (register-system (self :world) sys-draw-circle)))
 :update (fn game-update [self dt]
           (:update (self :world) dt)

           (when (key-pressed? :space)
             (:pause-game GS))))

(:add-state GS pause)
(:add-state GS game)

(:add-edge GS (gamestate/transition :pause-game :game :pause))
(:add-edge GS (gamestate/transition :unpause-game :pause :game))

(:goto GS :game)

# Jayley Code
# https://github.com/raysan5/raylib/blob/master/examples/shaders/shaders_custom_uniform.c

(init-window 800 480 "Test Game")
(set-target-fps 30)
(hide-cursor)

(def target (load-render-texture screen-width screen-height))

(while (not (window-should-close))
  (begin-drawing)
  (clear-background black)
  (:update GS 1)
  (draw-fps 10 10)
  (end-drawing)

  (begin-texture-mode target)
  (draw-circle 300 400 40 white)
  (end-texture-mode)
  (draw-texture (get-texture-default) 0 0 :white)
  (draw-texture-rec target.texture 0 0 screen-width screen-height [0 0] :white)
  )

(unload-render-texture target)
(close-window)
