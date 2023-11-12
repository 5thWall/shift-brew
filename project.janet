(declare-project
  :name "shift-brew"
  :description ```Shift Brew for DB2023 Game Jam ```
  :version "0.0.0"
  :dependencies ["https://github.com/janet-lang/jaylib.git"
                 "https://github.com/5thWall/junk-drawer.git"])

(declare-executable
  :name "shift-brew"
  :entry "shift-brew/init.janet")
