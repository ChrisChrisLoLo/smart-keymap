# ARTSEY 9-key layout (8 ARTSEY keys + 1 thumb key)
# Left-hand mirrored layout: S T R A / O I Y E / [thumb]
# Based on ARTSEY.io specification, simplified to 2-key chords only

let K = import "keys.ncl" in

let NUM_LAYER = 1 in

{
  # Base layer: 8 ARTSEY keys + thumb key
  keys = [
    # Row 1: S T R A
    K.S, K.T, K.R, K.A,
    # Row 2: O I Y E  
    K.O, K.I, K.Y, K.E,
    # Row 3: Thumb key (index 8)
    K.X,  # Thumb key only used in chords, no direct key
  ],

  # ARTSEY chords - all 2-key combinations only
  chords = [
    # Common letters (most frequent ARTSEY chords)
    # { indices = [0, 4], key = K.N },      # S + O = N
    # { indices = [1, 5], key = K.H },      # T + I = H
    # { indices = [2, 6], key = K.L },      # R + Y = L
    # { indices = [3, 7], key = K.D },      # A + E = D
    
    # More letters
    { indices = [0, 1], key = K.C },      # S + T = C
    { indices = [1, 2], key = K.P },      # T + R = P
    { indices = [2, 3], key = K.B },      # R + A = B
    { indices = [4, 5], key = K.F },      # O + I = F
    { indices = [5, 6], key = K.U },      # I + Y = U
    { indices = [20, 7], key = K.W },      # Y + E = W
    
    # Less common letters using thumb key (index 8)
    # { indices = [8, 0], key = K.G },      # Thumb + S = G
    # { indices = [8, 1], key = K.M },      # Thumb + T = M
    # { indices = [8, 2], key = K.K },      # Thumb + R = K
    # { indices = [8, 3], key = K.V },      # Thumb + A = V
    
    # Rare letters using thumb key
    # { indices = [8, 4], key = K.J },      # Thumb + O = J
    # { indices = [8, 5], key = K.Q },      # Thumb + I = Q
    # { indices = [8, 6], key = K.X },      # Thumb + Y = X
    # { indices = [8, 7], key = K.Z },      # Thumb + E = Z
    
    # Essential keys
    # { indices = [0, 3], key = K.Backspace }, # S + A = Backspace
    # { indices = [4, 7], key = K.Return },    # O + E = Enter
    # { indices = [1, 6], key = K.Tab },       # T + Y = Tab
    # { indices = [2, 5], key = K.Escape },    # R + I = Escape
    # { indices = [0, 7], key = K.Delete },    # S + E = Delete
    # { indices = [0, 6], key = K.Space },     # S + Y = Space
    
    # Basic punctuation
    # { indices = [0, 2], key = K.Comma },     # S + R = ,
    # { indices = [1, 7], key = K.Dot },       # T + E = .
    # { indices = [3, 5], key = K.Semicolon }, # A + I = ;
    # { indices = [4, 6], key = K.Apostrophe }, # O + Y = '
    
    # Additional punctuation using different combinations
    # { indices = [0, 5], key = K.Slash },     # S + I = /
    # { indices = [1, 4], key = K.Minus },     # T + O = -
    # { indices = [3, 6], key = K.Equal },     # A + Y = =
    # { indices = [2, 4], key = K.LeftBracket }, # R + O = [
    # { indices = [1, 3], key = K.RightBracket }, # T + A = ]
  ],

  layers = [
    # Base layer - all chords handled above
    [
      K.S, K.T, K.R, K.A,
      K.O, K.I, K.Y, K.E,
      K.X,  # Thumb key (transparent, only used in chords)
    ],
    
    # Numbers layer (accessed by holding S - to be implemented later)
    [
      K.N1, K.N2, K.N3, K.N4,
      K.N5, K.N6, K.N7, K.N8,
      K.N0,
    ],
  ],
}