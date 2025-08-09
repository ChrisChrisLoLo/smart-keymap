# ARTSEY 9-key layout (8 ARTSEY keys + 1 thumb key)
# Left-hand mirrored layout: S T R A / O I Y E / [thumb]
# Based on ARTSEY.io specification

let K = import "keys.ncl" in

let NUM_LAYER = 1 in

{
  # Base layer: 8 ARTSEY keys + thumb key (unused for now)
  keys = [
    # Row 1: S T R A
    K.S, K.T, K.R, K.A,
    # Row 2: O I Y E  
    K.O, K.I, K.Y, K.E,
    # Row 3: Thumb key (unused for now)
    K.TTTT,
  ],

  # ARTSEY chords for basic letters and common keys
  chords = [
    # Common letters (most frequent ARTSEY chords)
    { indices = [0, 4], key = K.N },      # S + O = N
    { indices = [1, 5], key = K.H },      # T + I = H
    { indices = [2, 6], key = K.L },      # R + Y = L
    { indices = [3, 7], key = K.D },      # A + E = D
    
    # More letters
    { indices = [0, 1], key = K.C },      # S + T = C
    { indices = [1, 2], key = K.P },      # T + R = P
    { indices = [2, 3], key = K.B },      # R + A = B
    { indices = [4, 5], key = K.F },      # O + I = F
    { indices = [5, 6], key = K.U },      # I + Y = U
    { indices = [6, 7], key = K.W },      # Y + E = W
    
    # Three-key chords for less common letters
    { indices = [0, 1, 2], key = K.G },   # S + T + R = G
    { indices = [1, 2, 3], key = K.M },   # T + R + A = M
    { indices = [4, 5, 6], key = K.K },   # O + I + Y = K
    { indices = [5, 6, 7], key = K.V },   # I + Y + E = V
    
    # Four-key chords for rare letters
    { indices = [0, 1, 2, 3], key = K.J }, # S + T + R + A = J
    { indices = [4, 5, 6, 7], key = K.Q }, # O + I + Y + E = Q
    { indices = [0, 4, 1, 5], key = K.X }, # S + O + T + I = X
    { indices = [2, 6, 3, 7], key = K.Z }, # R + Y + A + E = Z
    
    # Essential keys
    { indices = [7], key = K.Space },      # E = Space (single key for convenience)
    { indices = [0, 3], key = K.Backspace }, # S + A = Backspace
    { indices = [4, 7], key = K.Return },    # O + E = Enter
    { indices = [1, 6], key = K.Tab },       # T + Y = Tab
    { indices = [2, 5], key = K.Escape },    # R + I = Escape
    
    # Basic punctuation
    { indices = [0, 2], key = K.Comma },     # S + R = ,
    { indices = [1, 7], key = K.Dot },       # T + E = .
    { indices = [3, 5], key = K.Semicolon }, # A + I = ;
    { indices = [4, 6], key = K.Apostrophe }, # O + Y = '
  ],

  # Layer access (hold S for numbers layer - to be implemented later)
  custom_keys = fun K => {
    S_NUM = K.S & K.hold (K.layer_mod.hold NUM_LAYER),
  },

  layers = [
    # Base layer - all chords handled above
    [
      K.S, K.T, K.R, K.A,
      K.O, K.I, K.Y, K.E,
      K.TTTT,
    ],
    
    # Numbers layer (accessed by holding S)
    [
      K.N1, K.N2, K.N3, K.N4,
      K.N5, K.N6, K.N7, K.N8,
      K.N0,
    ],
  ],
}