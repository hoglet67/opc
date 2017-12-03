 // Insert the SDL library source code as a separate section

GET "libhdr"

GLOBAL {
  a:ug
  b
  size
  limit    // The iteration limit
}

MANIFEST {
  One   = 1<<20      // The number representing 1.00000000 in a 12.20b fixed point system

  width = 320        // BBC plot area
  height= 256
  
  VDU_GCOL   = 18     // Constants for the BBC graphics routines
  VDU_CLRGFX = 16
  VDU_CLRTXT = 12
  VDA_GRAORG = 29
  VDU_PLOT   = 25
  VDU_MODE   = 22
  GMOVE      =  4
  GDRAW      =  5
  GTRI       = 85
 
  GCOL2_BLACK  = 0     // Mode 2 colours
  GCOL2_RED    = 1
  GCOL2_GREEN  = 2
  GCOL2_YELLOW = 3
  GCOL2_BLUE   = 4
  GCOL2_MAGENTA= 5
  GCOL2_CYAN   = 6
  GCOL2_WHITE  = 7  
}

LET start() = VALOF
{ LET s = 0           // Region selector

  IF ~istubeplatform(1) DO {
    writes("Sorry - this program only works in the Acorn BBC Microcomputer Tube environment*n")
    RESULTIS 0
  }

  // Default settings
  // a, b, size := -50_000_000, 0, 180_000_000
  a    := -(One >>1 )
  b    := 0
  size := muldiv(One,18,10)
  
  limit := 38

  IF 1<=s<=7 DO
  { LET limtab = TABLE  38,  38,  38,  54,  70,  //  0 
                        80,  90, 100, 100, 110,  //  5 
                       120, 130, 140, 150, 160,  // 10 
                       170, 180, 190, 200, 210,  // 15 
                       220                       // 20 
    limit := limtab!s

    //a, b, size := -52_990_000, 66_501_089,  50_000_000
    a    := -muldiv(One, 52_990_000, 100_000_000)
    b    := muldiv(One, 66_501_089, 100_000_000)
    size := muldiv(One, 50_000_000, 100_000_000)
    FOR i = 1 TO s DO size := size / 10
  }

  VDU(VDU_MODE,2)       // Get colours rather than resolution
  writes("Mandelbrot")

  plotset()

  RESULTIS 0
}

AND plotset() BE {
  LET mina = a - size
  LET minb = b - size
  LET doublesize = 2 * size
  LET newcolour,colour = 0,0
  LET screenx,screeny = ?,?
  VDU(VDU_GCOL,0,colour)
  FOR x = 0 TO (width-1) DO {
    FOR y = 0 TO (height-1) DO {  
        LET itercount = ?
        LET p, q = ?, ?
    
        // Calculate c = p + iq corresponding to pixel (x,y)
        p := mina + muldiv(doublesize, x, width)
        q := minb + muldiv(doublesize, y, height)
    
        itercount := mandset(p, q, limit)    
    
        TEST itercount<0 
        THEN newcolour := GCOL2_BLACK
        ELSE newcolour := muldiv(itercount,7,limit)  // Pick from 8 (0-7) colours for full range
    
        UNLESS newcolour = colour DO {
            VDU(VDU_GCOL,0,newcolour)
            colour := newcolour
        }
        screenx := x << 2 // BBC coordinate system is 0..1024 all modes
        screeny := y << 2 
        VDU(VDU_PLOT,GMOVE,screenx, screeny)  
        VDU(VDU_PLOT,GDRAW,screenx, screeny)
      }
  }
}

AND mandset(a, b, n) = VALOF
{ LET x, y = 0, 0  // z = x + iy is initially zero
                   // c = a + ib is the point we are testing
  LET x3,y3,t, rsq = 0,0,0,0
  
  FOR i = 0 TO n DO {
    rsq := muldiv12p20(x3, x3) + muldiv12p20(y3, y3)  
    x3 := x/3 // To avoid possible overflow
    y3 := y/3 
    // Test whether z is diverging, ie is x^2+y^2 > 1
    IF rsq > One RESULTIS i
    // Square z and add c
    // Note that (x + iy)^2 = (x^2-y^2) + i(2xy)
    t := muldiv12p20(x<<1, y) + b
    x := muldiv12p20(x, x) - muldiv12p20(y, y) + a
    y := t 
  }
  // z did not diverge after n iterations
  RESULTIS -1
}


AND muldiv16p16(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 0)
}
AND muldiv12p20(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 1)
}
AND muldiv8p24(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 2)
}

/* -------------------------------------------------------------
 *
 * BBC Graphics routines - to be split into a new library later
 *
 * ------------------------------------------------------------- */

AND istubeplatform(verbose) = VALOF {
  LET platform_str = ?
  LET platform_id = sys(Sys_platform)
  platform_id := platform_id - 32
  SWITCHON ( platform_id ) INTO {
    DEFAULT: platform_str := 0; ENDCASE  
    CASE 0 : platform_str := "Electron"; ENDCASE
    CASE 1 : platform_str := "BBC Micro"; ENDCASE
    CASE 2 : platform_str := "BBC B+"; ENDCASE
    CASE 3 : platform_str := "Master 128"; ENDCASE
    CASE 4 : platform_str := "Master ET"; ENDCASE
    CASE 5 : platform_str := "Master Compact"; ENDCASE
    CASE 6 : platform_str := "RISC OS"; ENDCASE
  }
  TEST (platform_str & verbose) DO {
     writef("Detected Acorn Tube host as %s (%I )*n*c", platform_str, platform_id)
     RESULTIS 1
  } ELSE {
     RESULTIS 0  
  }       
}

AND lowbyte(n) = VALOF {
  RESULTIS (n & #x00FF)
}

AND highbyte(n) = VALOF {
  RESULTIS ((n & #xFF00) >> 8)
}

AND VDU29(x,y) BE {  
  LET s = VEC 6
  s%0 := 5
  s%1 := 29    
  s%2 := lowbyte(x)
  s%3 := highbyte(x)                
  s%4 := lowbyte(y)
  s%5 := highbyte(y)            
  writes(s)
}
    
AND VDU(n,a,b,c,d,e) BE {
  LET s = VEC 8
    
  s%0 := 6
  s%1 := lowbyte(n)    
  s%2 := lowbyte(a)
  s%3 := lowbyte(b)
  s%4 := highbyte(b)        
  s%5 := lowbyte(c)
  s%6 := highbyte(c)

  SWITCHON n INTO {
    DEFAULT:         s%0 := 6 ; ENDCASE
    CASE VDU_CLRGFX: s%0 := 1 ; ENDCASE
    CASE VDU_CLRTXT: s%0 := 1 ; ENDCASE    
    CASE VDU_MODE:   s%0 := 2 ; ENDCASE
    CASE VDU_GCOL:   s%0 := 3 ; ENDCASE
    CASE VDU_PLOT:   s%0 := 6 ; ENDCASE        
  }
  TEST s%0 = 1 THEN
    wrch( s%1)
  ELSE
    writes(s)
}











    