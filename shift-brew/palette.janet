# Catpuccin Colors
(defn normalize-color [rgb]
  (map |(/ $ 255) rgb))

(defmacro def-color [color rgb]
  ~(def ,color (normalize-color ',rgb)))

(defmacro def-palette
  "Create a palette struct"
  [& args]
  (def colors @{})

  (let [palette-name (first args)
        color-rbg (slice args 1)]
    (each [color rbg] (partition 2 color-rbg)
      (put colors (keyword color) (normalize-color rbg)))

    ~(def ,palette-name ,(table/to-struct colors))))

(def-palette catppuccin-mocha
  :rosewatter [245 224 220]
  :flamingo [224 205 205]
  :pink [245 194 231]
  :mauve [203 166 247]
  :red [243 139 168]
  :maroon [235 160 172]
  :peach [250 179 135]
  :yellow [249 226 175]
  :green [166 227 161]
  :teal [148 226 213]
  :sky [137 220 235]
  :sapphire [116 199 236]
  :blue [137 180 250]
  :lavender [180 190 254]
  :text [205 214 244]
  :subtext1 [186 194 222]
  :subtext0 [166 173 200]
  :overlay2 [147 153 178]
  :overlay1 [127 132 156]
  :overlay0 [108 112 134]
  :surface2 [88 91 112]
  :surface1 [69 71 90]
  :surface0 [49 50 68]
  :base [30 30 46]
  :mantle [24 24 37]
  :crust [17 17 27])

(def-color rosewater [245 224 220])
(def-color flamingo [242 205 205])
(def-color pink [245 194 231])
(def-color mauve [203 166 247])
(def-color red [243 139 168])
(def-color maroon [235 160 172])
(def-color peach [250 179 135])
(def-color yellow [249 226 175])
(def-color green [166 227 161])
(def-color teal [148 226 213])
(def-color sky [137 220 235])
(def-color sapphire [116 199 236])
(def-color blue [137 180 250])
(def-color lavender [180 190 254])
(def-color text [205 214 244])
(def-color subtext1 [186 194 222])
(def-color subtext0 [166 173 200])
(def-color overlay2 [147 153 178])
(def-color overlay1 [127 132 156])
(def-color overlay0 [108 112 134])
(def-color surface2 [88 91 112])
(def-color surface1 [69 71 90])
(def-color surface0 [49 50 68])
(def-color base [30 30 46])
(def-color mantle [24 24 37])
(def-color crust [17 17 27])
