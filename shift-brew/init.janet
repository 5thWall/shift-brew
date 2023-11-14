(use jaylib)
(use junk-drawer)
(use ./palette)

(def *screen-width* 600)
(def *screen-height* 400)
(def *gravity* 0.89)
(def *damp* 0.45)
(def *friction* 0.9999999999)

(def GS (gamestate/init))

# Array of rectangles
(def *cup*
  [
   # WALL
   # [0 (/ *screen-height* 2) *screen-width* 10]

   # BASE
   [(- (/ *screen-width* 2) 110)
    (- *screen-height* 50)
    220 20]

   #big left wall
   [(- (/ *screen-width* 2) 110)
    (- *screen-height* 300)
    20 270]

   # big right wall
   [(+ (/ *screen-width* 2) 90)
    (- *screen-height* 300)
    20 270]

   # Left
   # [(- (/ *screen-width* 2) 105)
   #  (- *screen-height* (+ 50 50))
   #  10 50]
   # [(- (/ *screen-width* 2) 110)
   #  (- *screen-height* (+ 50 50 45))
   #  10 50]
   # [(- (/ *screen-width* 2) 115)
   #  (- *screen-height* (+ 50 50 45 45))
   #  10 50]
   # [(- (/ *screen-width* 2) 120)
   #  (- *screen-height* (+ 50 50 45 45 45))
   #  10 50]
   # [(- (/ *screen-width* 2) 125)
   #  (- *screen-height* (+ 50 50 45 45 45 45))
   #  10 50]
   # [(- (/ *screen-width* 2) 130)
   #  (- *screen-height* (+ 50 50 45 45 45 45 45))
   #  10 50]

   # Right
   # [(+ (/ *screen-width* 2) 95)
   #  (- *screen-height* (+ 50 50))
   #  10 50]
   # [(+ (/ *screen-width* 2) 100)
   #  (- *screen-height* (+ 50 50 45))
   #  10 50]
   # [(+ (/ *screen-width* 2) 105)
   #  (- *screen-height* (+ 50 50 45 45))
   #  10 50]
   # [(+ (/ *screen-width* 2) 110)
   #  (- *screen-height* (+ 50 50 45 45 45))
   #  10 50]
   # [(+ (/ *screen-width* 2) 115)
   #  (- *screen-height* (+ 50 50 45 45 45 45))
   #  10 50]
   # [(+ (/ *screen-width* 2) 120)
   #  (- *screen-height* (+ 50 50 45 45 45 45 45))
   #  10 50]
   ])

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
    (:multiply vel *friction*)
    (if (< (vector/vlength vel) 0.3)
      (:multiply vel 0))
    (:add vel (vector/new 0 *gravity*))))

(def-system sys-element-cup-collision
  { elements [:position :velocity :circle] }
  (each [pos vel elm] elements
    (each rec *cup*
      (when (check-collision-circle-rec [(pos :x) (pos :y)] (elm :radius) rec)
        (when (> (pos :y) (rec 1))
          (*= (vel :y) -1 *damp*)
          (+= (vel :y) (elm :radius)))
        (when (< (pos :y) (+ (rec 1) (rec 3)))
          (*= (vel :y) -1 *damp*)
          (-= (vel :y) (elm :radius)))
        (when (> (pos :x) (+ (rec 0) (rec 2)))
          (*= (vel :x) -1 *damp*)
          (+= (vel :x) (elm :radius)))
        (when (< (pos :x) (rec 0))
          (*= (vel :x) -1 *damp*)
          (-= (vel :x) (elm :radius)))
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
  (def checked @[])
  (loop [[ent1 pos1 vel1 elm1] :in elements
         [ent2 pos2 vel2 elm2] :in elements
         :unless (= ent1 ent2)
         :unless (in? [ent2 ent1] checked)]
    (when (check-collision-circles [(pos1 :x) (pos1 :y)] (elm1 :radius)
                                   [(pos2 :x) (pos2 :y)] (elm2 :radius))
      (let [dx (- (pos1 :x) (pos2 :x))
            dy (- (pos1 :y) (pos2 :y))
            vx (- (vel2 :x) (vel1 :x))
            vy (- (vel2 :y) (vel1 :y))
            dot (+ (* dx vx) (* dy vy))]
        (when (> dot 0)
          (array/push checked [ent1 ent2])

          (put vel1 :x (/ (+ (vel1 :x) (* 2 dx)) 2))
          (put vel1 :y (/ (+ (vel1 :y) (* 2 dy)) 2))
          (put vel2 :x (/ (+ (- (vel2 :x)) (* 2 dy)) 2))
          (put vel2 :y (/ (+ (- (vel2 :y)) (* 2 dy)) 2))
          (*= (vel1 :x) *damp*)
          (*= (vel1 :y) *damp*)
          (*= (vel2 :x) *damp*)
          (*= (vel2 :y) *damp*)

          # move element
          (put pos1 :x (+ (pos1 :x) (vel1 :x)))
          (put pos1 :y (+ (pos1 :y) (vel1 :y)))
          (put pos2 :x (+ (pos2 :x) (vel2 :x)))
          (put pos2 :y (+ (pos2 :y) (vel2 :y)))

          (put elm1 :color sapphire)
          (put elm2 :color sapphire)
          )))))

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
            # add initial circles
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
                         (velocity :x (- 1 (* 2 (math/random))) :y 10)
                         (gravity)
                         (circle :radius 7 :color green)))))

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
