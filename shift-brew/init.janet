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

(defn in? [element list]
  (var found? false)
    (loop [el :in list
           :until found?]
      (if (= el element)
        (set found? true)))
    found?)

(def-system sys-element-element-collision
  { elements [:entity :position :velocity :circle] }
  (loop [[ent1 pos1 vel1 elm1] :in elements
         [ent2 pos2 vel2 elm2] :in elements]
    (def checked @[])
    (def posc @{ :x (+ (pos1 :x) (vel1 :x))
                :y (+ (pos1 :y) (vel1 :y)) })
    (when (and (not= ent1 ent2)
               (not (in? [ent2 ent1] checked))
               (check-collision-circles [(posc :x) (posc :y)] (elm1 :radius)
                                        [(pos2 :x) (pos2 :y)] (elm2 :radius)))
      (print "OOF!")
      (array/push checked [ent1 ent2])

      (def tan1 (:normalize (vector/new (- (- (pos2 :x) (pos1 :x)))
                                       (- (pos2 :y) (pos1 :y)))))
      (def tan2 (vector/rotate tan1 math/pi))
      (def rv1 (:multiply (vector/new (- (vel2 :x) (vel1 :y))
                                     (- (vel2 :y) (vel1 :y)))
                         0.5))
      (def rv2 (:multiply rv1 -1))
      (let [{ :x nx1 :y ny1 } (vector/mirror-on rv1 tan1)
            { :x nx2 :y ny2 } (vector/mirror-on rv2 tan2)]
        (put vel1 :x (+ (- (vel1 :x) nx2) nx1))
        (put vel1 :y (+ (- (vel1 :y) ny2) ny1))
        (put vel2 :x (+ (- (vel2 :x) nx1) nx2))
        (put vel2 :y (+ (- (vel2 :y) ny1) ny2)))
      (put elm1 :color sapphire)
      (put elm2 :color sapphire)
      ))

  (defn loop-test [elements]
    (loop [e1 :in elements
           e2 :in elements]
      (printf "%i, %i" e1 e2))))

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
            # (loop [i :range [1 25]]
            #   (let [x (- 200 (* 400 (math/random)))
            #         y (* 200 (math/random))
            #         dx (- 1 (* 2 (math/random)))
            #         dy (- 1 (* 2 (math/random)))]
            #     (add-entity world
            #                 (position :x (+ (/ *screen-width* 2) x) :y y)
            #                 (velocity :x dx :y dy)
            #                 (gravity)
            #                 (circle :radius 5 :color green))))

           # Systems
            (register-system world sys-element-cup-collision)
            (register-system world sys-element-element-collision)
            (register-system world sys-move)
            (register-system world sys-gravity)
            (register-system world sys-draw-circle)
            (register-system world sys-draw-cup)
            ))

 :update (fn game-update [self dt]
           (:update (self :world) dt)

           (when (key-pressed? :space)
             (add-entity (self :world)
                         (position :x (/ *screen-width* 2) :y 25.0)
                         (velocity :x (- 2 (* 4 (math/random))) :y 2.2)
                         (gravity)
                         (circle :radius 5 :color green)))))

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
