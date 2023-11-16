(use jaylib)
(use junk-drawer)
(use ./palette)

(def *screen-width* 600)
(def *screen-height* 400)
(var filling false)
(def *fill-types* [:bus :banter :auction :contest :game :dance])
(def *color-map*
  { :bus red
    :banter peach
    :auction blue
    :contest green
    :game yellow
    :dance mauve })

(var filled-amount 0)
(var fill-type :game)
(def *button-height* 30)

(def GS (gamestate/init))

(def *cup-color* sky)
(def *cup*
  [
   # BASE
   [(- (/ *screen-width* 2) 110)
    (- *screen-height* 50)
    220 20]

   # LEFT
   [(- (/ *screen-width* 2) 110)
    (- *screen-height* 300)
    20 270]

   # RIGHT
   [(+ (/ *screen-width* 2) 90)
    (- *screen-height* 300)
    20 270]
   ])

(def *fill-base-x* (- (/ *screen-width* 2) 100))
(def *fill-base-y* (- *screen-height* 49))
(def *fill-width* 200)

# Components
(def-component element :type :keyword :amount :number)
(def-component ui-element :type :keyword)
(def-component-alias position vector/from-named)
(def-component-alias size vector/from-named)

# System Callbacks
(def-system sys-fill
  { world :world }
  (if filling
    (++ filled-amount)
    (when (> filled-amount 3)
      (add-entity world (element :type fill-type :amount filled-amount))
      (set filled-amount 0))))

(def-system sys-draw-fill
  { world :world
    elements [:element] }

  (if filling
    (draw-rectangle (+ 5 (/ *screen-width* 2)) 0 10 *fill-base-y* (*color-map* fill-type)))

  (var top-base *fill-base-y*)
  (loop [[{ :type type :amount amount }] :in elements
         :before (-= top-base amount)]
    (draw-rectangle
      *fill-base-x* top-base
      *fill-width* amount
      (*color-map* type)))

  (draw-rectangle
    *fill-base-x* (- top-base filled-amount)
    *fill-width* filled-amount
    (*color-map* fill-type))
  )

(def-system sys-draw-cup
  { wld :world }
  (each rec *cup*
    (draw-rectangle-rec rec *cup-color*)))

(def-system sys-draw-ui
  { buttons [:ui-element :position :size] }
  (each [element pos size] buttons
    (draw-rectangle-v (vector/unpack pos) (vector/unpack size) (*color-map* (element :type)))
    (draw-text (string (element :type))
               ;(vector/unpack (:add (vector/clone pos) 7))
               20 base)
    (draw-text (string (element :type))
               ;(vector/unpack (:add (vector/clone pos) 5))
               20 text))
  (draw-rectangle 0 *button-height* *screen-width* (/ *button-height* 2) (*color-map* fill-type)))

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
            (loop [[i type] :pairs *fill-types*]
              (add-entity world
                          (ui-element :type type)
                          (position :x (* i (/ *screen-width* (length *fill-types*))) :y 0)
                          (size :x (/ *screen-width* (length *fill-types*)) :y *button-height*)))

            # Systems
            (register-system world sys-fill)
            (register-system world sys-draw-fill)
            (register-system world sys-draw-cup)
            (register-system world sys-draw-ui)
            ))

  :update (fn game-update [self dt]
            (:update (self :world) dt)

           (set filling (key-down? :space))

           (when (key-pressed? :p)
             (:pause-game GS)))
  )

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
  (clear-background crust)
  (:update GS 1)
  # (draw-fps 10 10)
  (end-drawing)
  )

(unload-render-texture target)
(close-window)
