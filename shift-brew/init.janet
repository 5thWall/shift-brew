(use jaylib)
(use junk-drawer)
(use ./palette)

(def GS (gamestate/init))

(def *screen-width* 600)
(def *screen-height* 400)
(def *fill-types* [:bus :banter :auction :contest :game :dance])
(def *color-map*
  { :bus red
    :banter peach
    :auction yellow
    :contest green
    :game blue
    :dance mauve })

(def *button-height* 30)

(def *fill-base-x* (+ 50 60 20))
(def *fill-base-y* (- *screen-height* 49))
(def *fill-width* 200)
(def *cup-color* overlay1)
(def *max-fill* (- 270 20 10))
(def *cup*
  [
   # BASE
   [(+ 50 60)
    (- *screen-height* 50)
    220 20]

   # LEFT
   [(+ 50 60)
    (- *screen-height* 300)
    20 270]

   # RIGHT
   [(+ 50 60 220)
    (- *screen-height* 300)
    20 270]

   # HANDLE MAIN
   [50 (- *screen-height* 255)
    20 150]

   # HANDLE TOP
   [50 (- *screen-height* 255)
    60 20]

   # HANDLE BOTTOM
   [50 (- *screen-height* 105)
    60 20]
   ])

(def *shifts*
  [{ :name "Crab Rave"
     :elements [{ :type :bus
                  :amount 60 }
                { :type :game
                  :amount 60 }
                { :type :auction
                  :amount 60 }
                { :type :dance
                  :amount 60 }] }
  ])

(def *hour-ticks* (* 30 10))

# Global vars
(var shift (*shifts* 0))
(var fill-latch? false)
(var filling? false)
(var filled-amount 0)
(var fill-type :bus)
(var type-i 0)
(var total-hours 1)
(var hours 0)
(var points 0)
(var to-next-hour 10)

# Components
(def-component element :type :keyword :amount :number)
(def-component ui-element :type :keyword)
(def-component-alias position vector/from-named)
(def-component-alias size vector/from-named)

# Utility
(defn latch! []
  (set fill-latch? false))

(defn reset! []
  (latch!)
  (set filled-amount 0))

(defn score [_]
  (+= points 100)
  (++ total-hours))

# System Callbacks
(def-system sys-fill
  { world :world }
  (if filling?
    (++ filled-amount)
    (when (> filled-amount 3)
      (add-entity world (element :type fill-type :amount filled-amount))
      (set filled-amount 0))))

(def-system sys-draw-shift { world :world }
  (var top-base *fill-base-y*)
  (each { :type t :amount a } (shift :elements)
    (-= top-base a)
    (let [color (*color-map* t)]
      (draw-line-ex [*fill-base-x* top-base]
                    [(+ *fill-base-x* *fill-width*) top-base]
                    2 color)
      # (draw-text (string t)
      #            (+ *fill-base-x* 32) (+ top-base 7)
      #            20 overlay0)
      (draw-text (string t)
                 (+ *fill-base-x* 30) (+ top-base 5)
                 20 color)))
  (draw-text (string/format "%s Shift" (shift :name))
             (+ *fill-base-x* 10)
             (+ *fill-base-y* 25)
             22 text))

(def-system sys-draw-fill { world :world
                           elements [:element] }
  (if filling? # Fill stream
    (draw-rectangle (- (+ *fill-base-x* (/ *fill-width* 2)) 5) *button-height*
                    10 (- *fill-base-y* *button-height*)
                    (*color-map* fill-type)))

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
    (*color-map* fill-type)))

(def-system sys-draw-cup { wld :world }
  (each rec *cup*
    (draw-rectangle-rec rec *cup-color*)))

(def-system sys-draw-ui
  { buttons [:ui-element :position :size] }
  (each [element pos size] buttons
    # Button portion
    (if (= (element :type) fill-type)
      (draw-rectangle-v (vector/unpack pos) (vector/unpack size) (*color-map* (element :type))))

    # Text Shadow
    (draw-text (string (element :type))
               ;(vector/unpack (:add (vector/clone pos) 7))
               20 base)
    # Text
    (draw-text (string (element :type))
               ;(vector/unpack (:add (vector/clone pos) 5))
               20 text))
  # Selected
  (draw-rectangle 0 *button-height* *screen-width* (/ *button-height* 2) (*color-map* fill-type)))

(def-system sys-draw-score { world :world }
  (let [txtx (- *screen-width* 200)
        txtymid (/ *screen-height* 2)]
    (draw-text (string/format "$%i Raised!" points) txtx (- txtymid 35) 20 text)
    (draw-text (string/format "%i hours of" hours) txtx (- txtymid 10) 20 text)
    (draw-text (string/format "%i so far" total-hours) txtx (+ txtymid 10) 20 text)))

(def-system sys-score { wld :world
                        elements [:entity :element] }
  (var total-fill
    (reduce
      (fn [acc el] (+ acc el))
      filled-amount
      (mapcat (fn [el] ((el 1) :amount)) elements)))

  (when (>= total-fill *max-fill*)
    (score (mapcat (fn [el] (el 1)) elements))
    (reset!)
    (each [ent _] elements (remove-entity wld ent))))

(def-system sys-game-over { wld :world
                           elements [:entity :element] }
  (when (= hours total-hours)
    # Clean up entities here
    (each [ent _] elements (remove-entity wld ent))
    (print "GAME OVER")
    (:fail GS)))

(gamestate/def-state gameover
  :update (fn gameover-update [self dt]
            (when (key-pressed? :space)
              # Restart the game
              (reset!)
              (set total-hours 1)
              (set hours 0)
              (set type-i 0)
              (:restart GS))
            (draw-text "GAME\nOVER" (/ *screen-width* 2) (/ *screen-height* 2) 30 red)))

(gamestate/def-state game
  :world (create-world)
  :init (fn game-init [self]
          (let [world (get self :world)]
            (loop [[i type] :pairs *fill-types*]
              (add-entity world
                          (ui-element :type type)
                          (position :x (* i (/ *screen-width* (length *fill-types*))) :y 0)
                          (size :x (/ *screen-width* (length *fill-types*)) :y *button-height*)))

            (timers/every world *hour-ticks*
                          (fn [wld dt] (++ hours)))

            # Systems
            (register-system world timers/update-sys)
            (register-system world sys-fill)
            (register-system world sys-draw-shift)
            (register-system world sys-draw-fill)
            (register-system world sys-draw-cup)
            (register-system world sys-draw-ui)
            (register-system world sys-draw-score)
            (register-system world sys-score)
            # (register-system world sys-game-over)
            ))

  :update (fn game-update [self dt]
            (:update (self :world) dt)
            (if (and (key-up? :space)
                     (not fill-latch?))
              (set fill-latch? true))
            (set filling? (and fill-latch? (key-down? :space)))
            (when (not filling?)
              (if (key-pressed? :left)
                (if (> type-i 0) (-- type-i)))
              (if (key-pressed? :right)
                (if (< type-i (- (length *fill-types*) 1)) (++ type-i))))

            (set fill-type (*fill-types* type-i))))

(:add-state GS game)
(:add-state GS gameover)

(:add-edge GS (gamestate/transition :fail :game :gameover))
(:add-edge GS (gamestate/transition :restart :gameover :game))

(:goto GS :game)

(defn main [& args]
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
  (close-window))
