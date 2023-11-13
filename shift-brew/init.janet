(use jaylib)
(use junk-drawer)
(use ./palette)

(def *screen-width* 800)
(def *screen-height* 800)
(def *grav-constant* 0.3)
(def *damp* 0.8)

(def GS (gamestate/init))

# Array of rectangles
(def *cup*
  [
   # WALL
   # [0 (/ *screen-height* 2) *screen-width* 10]

   # BASE
   [(- (/ *screen-width* 2) 100)
    (- *screen-height* 55)
    200 10]

   # Left
   [(- (/ *screen-width* 2) 105)
    (- *screen-height* (+ 50 50))
    10 50]
   [(- (/ *screen-width* 2) 110)
    (- *screen-height* (+ 50 50 45))
    10 50]
   [(- (/ *screen-width* 2) 115)
    (- *screen-height* (+ 50 50 45 45))
    10 50]
   [(- (/ *screen-width* 2) 120)
    (- *screen-height* (+ 50 50 45 45 45))
    10 50]

   # Right
   [(+ (/ *screen-width* 2) 95)
    (- *screen-height* (+ 50 50))
    10 50]
   [(+ (/ *screen-width* 2) 100)
    (- *screen-height* (+ 50 50 45))
    10 50]
   [(+ (/ *screen-width* 2) 105)
    (- *screen-height* (+ 50 50 45 45))
    10 50]
   [(+ (/ *screen-width* 2) 110)
    (- *screen-height* (+ 50 50 45 45 45))
    10 50]])

# Components
(def-component-alias position vector/from-named)
(def-component-alias velocity vector/from-named)
(def-component circle :radius :number :color (any))
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

(def-system sys-draw-cup
  { wld :world }
  (each rec *cup*
    (draw-rectangle-rec rec blue)))

(def-system sys-gravity
  { falling [:velocity :gravity] }
  (each [vel] falling
    (put vel :y (+ (vel :y) (* dt *grav-constant*)))))

(defn between [comp first second]
  (if (> first second)
    (and (< first comp) (> second comp))
    (and (> first comp) (< second comp))))

(def-system sys-element-cup-collision
  { elements [:position :velocity :circle] }
  (each [pos vel elm] elements
    (each rec *cup*
      (when (check-collision-circle-rec [(pos :x) (pos :y)] (elm :radius) rec)
        (if (not (between (pos :x) (rec 0) (+ (rec 0) (rec 2))))
          (put vel :x (- (* (vel :x) *damp*))))
        (if (not (between (pos :y) (rec 1) (+ (rec 1) (rec 3))))
          (put vel :y (- (* (vel :y) *damp*))))
        (put elm :color red)))))

(def-system sys-element-element-collision
  { elements [:position :velocity :circle] }
  (each [pos1 vel1 elm1] elements
    (each [pos2 vel2 elm2] elements
      (def posc @{ :x (+ (pos1 :x) (vel1 :x))
                   :y (+ (pos1 :y) (vel1 :y)) })
      (when (and (not (and (= pos1 pos2) (= vel1 vel2)))
                 (check-collision-circles [(posc :x) (posc :y)] (elm1 :radius)
                                          [(pos2 :x) (pos2 :y)] (elm2 :radius)))
        (def t1 (:normalize (vector/new (- (- (pos2 :x) (pos1 :x)))
                                             (- (pos2 :y) (pos1 :y)))))
        (def rv1 (vector/new (- (vel2 :x) (vel1 :y))
                                 (- (vel2 :y) (vel1 :y))))
        # (def vec-len (vector/length (vector/preject-on rel-vel tangent)))
        # Subtract relative velocity projected on tangent
        # Add relative velocity mirrored on tangent
        (let [{ :x nx :y ny } (vector/mirror-on rv1 t1)]
          (put vel1 :x nx)
          (put vel1 :y nx))
        (put elm1 :color sapphire)))))

(defn loop-test [elements]
  (loop [e1 :iterate (array/pop elements)
         e2 :in elements]
    (printf "%i, %i" e1 e2)))

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
            (loop [i :range [1 10]]
              (let [x (- 100 (* 200 (math/random)))
                    y (* 100 (math/random))
                    dx (- 1 (* 2 (math/random)))
                    dy (- 1 (* 2 (math/random)))]
                (add-entity world
                            (position :x (+ (/ *screen-width* 2) x) :y y)
                            (velocity :x dx :y dy)
                            (gravity)
                            (circle :radius 5 :color green))))

            # (add-entity world
            #             (position :x (+ 50 (/ *screen-width* 2)) :y 25.0)
            #             (velocity :x (- 1 (* 2 (math/random))) :y 0)
            #             (gravity)
            #             (circle :radius 5 :color green))
            # (add-entity world
            #             (position :x (- 50 (/ *screen-width* 2)) :y 25.0)
            #             (velocity :x (- 1 (* 2 (math/random))) :y 0)
            #             (gravity)
            #             (circle :radius 5 :color green))

           # Systems
            (register-system (self :world) sys-move)
            (register-system (self :world) sys-gravity)
            (register-system (self :world) sys-element-cup-collision)
            (register-system (self :world) sys-element-element-collision)
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
