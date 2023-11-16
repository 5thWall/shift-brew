# Not going to do a physics thing actually
(def *gravity* 0.89)
(def *damp-ball* 1)
(def *damp-cup* 0.67)
(def *friction* 0.9999999999)

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
  (each [vel grav] falling
    (:multiply vel *friction*)
    (if (< (vector/vlength vel) 0.3)
      (:multiply vel 0))
    (unless (grav :landed)
      (:add vel (vector/new 0 *gravity*)))))

(def-system sys-element-cup-collision
  { elements [:position :velocity :circle :gravity] }
  (each [pos vel elm grav] elements
    (put grav :landed false)
    (each rec *cup*
      (when (check-collision-circle-rec [(pos :x) (pos :y)] (elm :radius) rec)
        (when (> (pos :y) (rec 1))
          (*= (vel :y) *damp-cup*)
          (:multiply vel (vector/new 0 -1))
          (+= (pos :y) (elm :radius)))
        (when (< (pos :y) (+ (rec 1) (rec 3)))
          (put grav :landed true)
          (*= (vel :y) *damp-cup*)
          (:multiply vel (vector/new 0 -1))
          (-= (pos :y) (elm :radius)))
        (when (> (pos :x) (+ (rec 0) (rec 2)))
          (*= (vel :x) *damp-cup*)
          (:multiply vel (vector/new -1 0))
          (+= (pos :x) (elm :radius)))
        (when (< (pos :x) (rec 0))
          (*= (vel :x) *damp-cup*)
          (:multiply vel (vector/new -1 0))
          (-= (pos :x) (elm :radius)))
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
  (var checked @[])
  (var colided? true)
  (loop [:while colided?
         :before (set colided? false)
         :after (set checked @[])
         [ent1 pos1 vel1 elm1] :in elements
         [ent2 pos2 vel2 elm2] :in elements
         :unless (= ent1 ent2)
         :unless (in? [ent2 ent1] checked)]
    (when (check-collision-circles [(pos1 :x) (pos1 :y)] (elm1 :radius)
                                   [(pos2 :x) (pos2 :y)] (elm2 :radius))
      (set colided? true)
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

          # move element
          (:add pos1 vel1)
          (:add pos2 vel2)
          # (put pos1 :x (+ (pos1 :x) (vel1 :x)))
          # (put pos1 :y (+ (pos1 :y) (vel1 :y)))
          # (put pos2 :x (+ (pos2 :x) (vel2 :x)))
          # (put pos2 :y (+ (pos2 :y) (vel2 :y)))

          (put elm1 :color sapphire)
          (put elm2 :color sapphire)
          )))))
