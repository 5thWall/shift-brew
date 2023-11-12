(use jaylib)
(use junk-drawer)
(use ./palette)

(def *screen-width* 800)
(def *screen-height* 800)
(def *grav-constant* 0.3)

(def GS (gamestate/init))

# Components
(def-component-alias position vector/from-named)
(def-component-alias velocity vector/from-named)
(def-component circle :radius :number :color (any))
(def-component cup
  :h :number
  :wb :number
  :wt :number
  :x :number
  :y :number
  )
(def-tag gravity)

# System Callbacks
(def-system sys-move
  {moveables [:position :velocity]}
  (each [pos vel] moveables
    (put pos :x (+ (pos :x) (* dt (vel :x))))
    (put pos :y (+ (pos :y) (* dt (vel :y))))))

(def-system sys-draw-circle
  { circles [:position :circle] }
  (each [pos circle] circles
    (draw-circle
      (math/floor (pos :x)) (math/floor (pos :y))
     (circle :radius) (circle :color))))

(defn cup-points
  "Returns struct of points on cup"
  [cup]
  { :tl { :x (- (cup :x) (cup :wt))
          :y (- (cup :y) (cup :h)) }
    :bl { :x (- (cup :x) (cup :wb))
          :y (cup :y) }
    :tr { :x (+ (cup :x) (cup :wt))
          :y (- (cup :y) (cup :h)) }
    :br { :x (+ (cup :x) (cup :wb))
          :y (cup :y) } })

(def-system sys-draw-cup
  { cups [:cup] }
  (each [cup] cups
    (let [{ :tl tl :bl bl :tr tr :br br } (cup-points cup)]
      (draw-line (tl :x) (tl :y) (bl :x) (bl :y) blue)
      (draw-line (bl :x) (bl :y) (br :x) (br :y) blue)
      (draw-line (br :x) (br :y) (tr :x) (tr :y) blue))))

(def-system sys-gravity
  { falling [:velocity :gravity] }
  (each [vel] falling
    (put vel :y (+ (vel :y) (* dt *grav-constant*)))))

(gamestate/def-state
  pause
  :update (fn pause-update [self dt]
            (draw-poly [100 100] 5 40 0 rosewater)

            (when (key-pressed? :space)
              (:unpause-game GS))))

(gamestate/def-state
  game
  :world (create-world)
  :init (fn game-init [self]
          (let [world (get self :world)]
            # Add initial circles
            (loop [i :range [1 5]]
              (add-entity world
                          (position :x (* i (/ *screen-width* 5)) :y 0.0)
                          (velocity :x 0 :y 0)
                          (gravity)
                          (circle :radius 5 :color peach)))

           (add-entity world
                       (cup :h 400 :wt 225 :wb 100
                            :x (/ *screen-width* 2) :y (- *screen-height* 50)))

           # Systems
           (register-system (self :world) sys-move)
           (register-system (self :world) sys-gravity)
           (register-system (self :world) sys-draw-circle)
           (register-system (self :world) sys-draw-cup)
           ))
 :update (fn game-update [self dt]
           (:update (self :world) dt)

           (when (key-pressed? :space)
             (:pause-game GS))))

(:add-state GS pause)
(:add-state GS game)

(:add-edge GS (gamestate/transition :pause-game :game :pause))
(:add-edge GS (gamestate/transition :unpause-game :pause :game))

(:goto GS :game)

(init-window *screen-width* *screen-height* "Shift Brew")
(set-target-fps 30)
(hide-cursor)

(def target (load-render-texture *screen-width* *screen-height*))

(while (not (window-should-close))
  (begin-drawing)
  (clear-background mantle)
  (:update GS 1)
  (draw-fps 10 10)
  (end-drawing)
  )

(unload-render-texture target)
(close-window)
