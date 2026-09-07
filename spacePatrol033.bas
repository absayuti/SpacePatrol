'============================================
'                    SPACE PATROL FOR Neo6502 
' 
' V 0.33  - 9 Aug 2026
'         - Tune for intro
'--------------------------------------------

CALL initialization()
CALL createTileMap()
CALL intro()
'--------------------------------------------
' Main loop
REPEAT
  CALL resetVars()
  CALL setupScreen()
  CALL setupAliens()
  ' Game loop
  REPEAT
    ' Get input
    IF EVENT(t1,2)
      fire = JOYPAD(dx,dy)
      IF dx<0 THEN facing = 0
      IF dx>0 THEN facing = 1
      x1 = x1+dx
      IF x1<0 THEN x1 = 320+x1
      x1 = x1 % 320
      CALL DrawTileMap(x1,0)
      ' Update craft's XY-position on screen
      y1 = max(y1+dy*2,0)
      IF y1>y1max THEN y1 = y1max
      SPRITE 0 IMAGE s.ship+facing+empty TO 10*16,y1
      ' Check if craft is docking --> reload ammo
      IF y1=y1max & empty THEN CALL reloadAmmo()
      ' Check if FIRE (key O or P) is pressed
      IF fire>0
        IF ammo>0
          CALL shootLaser()
          ammo = ammo-1: CALL updateAmmo()
        ELSE
          empty = 2: NOISE 0,30,10
        ENDIF
      ENDIF
    ENDIF
    ' Animate aliens
    FOR i=0 TO 9
      SPRITE i+10 IMAGE s.alien+galien TO xalien(i)*16+8,yalien(i)*16
    NEXT
    ' Change alien ship image
    IF (loopnum%5)=0 THEN galien = galien+1: IF galien=3 THEN galien = 0
    ' Drop a few aliens every 100 loops or so
    loopnum = loopnum+1
    IF loopnum%interval=0
      CALL dropAlien(anum)
      anum = anum+1: IF anum>9 THEN anum = 0
    ENDIF
    IF loopnum>dropmax THEN loopnum = 0
    ' Update score etc
    CALL updateScore()
    IF landed=5 THEN gameover = 1
  UNTIL gameover
  '
  TEXT "GAME OVER" INK c.red DIM 2 TO 7*16,3*16 
  CALL tuneGameOver()
  CALL playAgain(yesno)
UNTIL yesno = 0
'  
CLS
PRINT "Bye."
END

'============================================
'                                  RESET VARS
'	                       Reset game variables
'--------------------------------------------
PROC resetVars()
  x1 = 0: y1 = 7*16
  facing = 0: empty = 0: score = 0: gameover = 0
  level = 1: destroyed = 0: landed = 0: anum = 0
  fullammo = 20: ammo = fullammo
  loopnum = 0: interval = 10: dropmax = interval*10
  yesno = 1
ENDPROC

'============================================
'                                 SHOOT LASER
'	     
'--------------------------------------------
PROC shootLaser()
  LOCAL i, j, shot
  SFX 0,23
  i = 1
  DO
    IF facing
      SPRITE 1 IMAGE s.laser TO (10+i)*16,y1
    ELSE
      SPRITE 1 IMAGE s.laser TO (10-i)*16,y1
    ENDIF
    ' Check if it hits any alien ships
    shot = -1
    FOR j=0 TO 9
      IF HIT(1,10+j,12) THEN shot = j
    NEXT
    WAIT 1  
    i = i+1
    IF shot>-1 | i>9 THEN EXIT
  LOOP
  IF shot>-1
    SFX 0,21: NOISE 1,100,50,-80
    SPRITE shot+10 TO 0,-16  :'hide alien --> explosion
    SPRITE 1 IMAGE s.explode TO xalien(shot)*16+8,yalien(shot)*16
    WAIT 6
    SPRITE 1 IMAGE s.explode+1 TO xalien(shot)*16+8,yalien(shot)*16
    WAIT 4
    yalien(shot)=-1
    score = score+10*level
    destroyed = destroyed+1
    IF destroyed>19
      destroyed = 0
      level = level+1
      CALL updateLevel()
    ENDIF
  ENDIF
  SPRITE 1 TO -16,0 :'OFF the laser/explosion sprite
ENDPROC

'============================================
'                                 DROP ALIENS
'               Drop a few random aliens down
'--------------------------------------------
PROC dropAlien(n)
  LOCAL i, j, x, y, dy, yy, dup
  IF yalien(n)>0
    y = yalien(n) + RAND(level+1)        
    CALL checkOverlap(xalien(n), y, dup)
    IF dup=0
      dy = (y - yalien(n))/4
      FOR j=1 TO 4
        yy = yalien(n) + j*dy
        SPRITE n+10 IMAGE s.alien+galien TO xalien(n)*16+8,yy*16
        WAIT 1
      NEXT
      yalien(n) = y
      IF yalien(n) >= yover
        NOISE 1,1,70,500
        SPRITE n+10 IMAGE s.greenmen TO xalien(n)*16+8,yover*16+6
        WAIT 50
        'SPRITE n+10 IMAGE s.alien TO xalien(n)*16+8,yover*16
        yalien(n) = -1
        landed = landed+1
        CALL updateLanded()
      ENDIF
    ENDIF
  ELSE
    ' Or spawn a new one
    REPEAT 
      REPEAT
        x = RAND(19)+1
      UNTIL x<8 | x>10
      CALL checkOverlap( x, 1, dup )
    UNTIL dup=0
    xalien(n) = x
    yalien(n) = 1+RAND(level)
  ENDIF
  SPRITE n+10 IMAGE s.alien+galien TO xalien(i)*16+8,yalien(i)*16
ENDPROC

'============================================
'                                 RELOAD AMMO
'	                         Reload ammunitions
'--------------------------------------------
PROC reloadAmmo()
  LOCAL i, diff
  SPRITE 1 IMAGE s.reload TO 10*16,y1+12
  FOR i=0 TO 3
    diff = x1-xtower(i): IF diff<0 THEN diff = -diff
    IF diff<3 & ammo=0
      SFX 0,8: ammo = fullammo-4*(level-1): IF ammo<5 THEN ammo = 5
      CALL updateAmmo()
      empty = 0
      WAIT 50
    ENDIF
  NEXT
  SPRITE 1 TO -16,-16
ENDPROC

'============================================
'                                UPDATE SCORE
'--------------------------------------------
PROC updateScore()
  CURSOR 0,0: INK c.white
  PRINT "SCORE:";score;" "
ENDPROC

'============================================
'                                UPDATE SCORE
'--------------------------------------------
PROC updateLanded()
  LOCAL i
  CURSOR 14,0
  PRINT "ALERT"
  CURSOR 19,0
  IF landed
    INK c.orange
    FOR i=1 TO landed
      PRINT CHR$(192);
    NEXT
  ELSE 
    INK c.grey
      FOR i=1 TO 5
      PRINT CHR$(192);
    NEXT
  ENDIF
ENDPROC

'============================================
'                                 UPDATE AMMO
'	     Shows how much ammunition the ship has
'--------------------------------------------
PROC updateAmmo()
  LOCAL m, n, i
  CURSOR 25,0: INK c.white
  PRINT "AMMO"
  m = INT(ammo/4)
  n = ammo%4
  IF m>0
    FOR i=1 TO m
      IMAGE t.ammo TO (10+i)*16,0
    NEXT
  ENDIF
  IF m<5 THEN IMAGE t.ammo+n+1 TO (11+m)*16,0
  IF m<4 
    FOR i=m+2 TO 5
      IMAGE t.ammo+1 TO (10+i)*16,0
    NEXT
  ENDIF
ENDPROC

'============================================
'                                UPDATE LEVEL
'--------------------------------------------
PROC updateLevel()
  LOCAL i
  SFX 0,3
  FOR i=1 TO 2
    CURSOR 45,0
    INK c.red
    PRINT "LEVEL ";level;" "
    WAIT 1
    CURSOR 45,0
    INK c.white
    PRINT "LEVEL ";level;" "
    WAIT 1
  NEXT
ENDPROC

'============================================
'                                DRAW TILEMAP
'	       This draws the tilemap offset by x,y
'--------------------------------------------
PROC DrawTileMap(xo,yo)
	' Draw the starry sky background
	TILEMAP backmap,xo,yo
  TILEDRAW 0,11*16 to 319,13*16
	' Draw the landscape a line before bottom
  x2 = (xo*2)%320
	TILEMAP midmap,x2,yo
  TILEDRAW 0,13*16 to 319,14*16
	' Draw the foreground at the bottom
  x4 = (xo*4)%320
	TILEMAP foremap,x4,yo
  TILEDRAW 0,14*16 to 319,15*16
ENDPROC

'============================================
'                              CREATE TILEMAP
'    This creates a single tile map in memory
'--------------------------------------------
PROC CreateTileMap()
  LOCAL a$, b$, a, c 
  ' 
  ' Create tilemap for the sky by randomly 
  ' putting STARs in the sky 
  width = 40: height = 2
  backmap = ALLOC(width*height+3)
  POKE backmap,1: POKE backmap+1,width: POKE backmap+2,height
  ' Empty background
  FOR r=0 TO height
    FOR c=0 TO width
      CALL setTile(backmap,width,c,r,127)
    NEXT
  NEXT
  ' Put buildings
  a$ = "GGGFFGGGGGGCGGGGFGGG"
  b$ = "AFEDDHAABABBBABEDHFB"
  a$ = a$+a$: b$ = b$+b$
  FOR c=0 TO LEN(a$)-1
      a = ASC(MID$(a$,c+1,1))-58
      CALL setTile(backmap,width,c,0,a)
  NEXT
  FOR c=0 TO LEN(b$)-1
      a = ASC(MID$(b$,c+1,1))-58
      CALL setTile(backmap,width,c,1,a)
  NEXT
  '
  ' Create tilemap for midground/landscape
	width = 40: height = 1
	' an array of memory with a small header : type, width and height.
	midmap = ALLOC(width*height+3)
	POKE midmap,1: POKE midmap+1,width: POKE midmap+2,height
	' Fill field with tiles
  a$ = "11211011311211021231"
  a$ = a$+a$
  FOR c=0 TO LEN(a$)-1
    a = ASC(MID$(a$,c+1,1))-ASC("0")
    CALL setTile(midmap,width,c,0,a)
  NEXT
  '
  ' Create tilemap for foreground
	width = 40: height = 1
	' an array of memory with a small header : type, width and height.
	foremap = ALLOC(width*height+3)
	POKE foremap,1: POKE foremap+1,width: POKE foremap+2,height
	' Fill field with tiles
  a$ = "44456445644445644564"
  a$ = a$+a$
  FOR c=0 TO LEN(a$)-1
    a = ASC(MID$(a$,c+1,1))-ASC("0")
    CALL setTile(foremap,width,c,0,a)
  NEXT
  '
ENDPROC

'============================================
'                                  SET A TILE
'       This sets a tile @ x,y in the tilemap
'--------------------------------------------
PROC setTile(map,wid,x,y,t)
	POKE map+x+3+y*wid,t
ENDPROC

'============================================
'                              INITIALIZATION
'--------------------------------------------
PROC initialization()
	'Set values for 16 colours
	c.black   = 0 
  c.red     = 1
  c.green   = 2 
  c.yellow  = 3
	c.blue    = 4
  c.magenta = 5
  c.cyan    = 6
  c.white   = 7
  c.grey    = 9
  c.green2  =10
  c.orange  =11
  c.orange2 =12
  c.brown   =13
  c.pink    =14
  c.grey2   =15
  'Tile numbers
  t.tower   = 0
  t.ground  = 1
  t.foregr  = 4
  t.buildg  = 7
  t.star    = 15
  t.ammo    = 17
  'Sprite numbers
  s.ship    = 128 :'left, right, left2, right2
  s.laser   = 132
  s.alien   = 133 :'3 images
  s.explode = 136
  s.reload  = 138
  s.greenmen= 139  
  'Main variables/limits
  DIM xalien(9), yalien(9)
  galien = 0
  ' X-posision of ammo towers
  DIM xtower(3)
  xtower(0)=36: xtower(1)=124: xtower(2)=196: xtower(3)=284
  y1max = 13*16-3
  yover = 13
  'Load graphic file
  CLS
  GLOAD "spacepatrol.gfx"
  SPRITE CLEAR
  '1 user-defined character
  DEFCHR 192,0,12,30,63,30,12,0
  'Music notes CDEFGAB
  DIM note(6)
  note(0) = 262: note(1) = 294: note(2) = 330: note(3) = 349  
  note(4) = 392: note(5) = 440: note(6) = 494
  no$ = "CDEFGAB"
  'Tune for intro - left hand & right hand
  tune$ = "CCGGAAG, FFEEDDC, GGFFEED, GGFFEED, CCGGAAG, FFEEDDC,"
  tune2$= "CGEGCGEE FCACGDCC CGEGGDBB CGEGGDBB CGEGCGEE FCACGDCC"
  tlen = LEN(tune$)
ENDPROC

'============================================
'                                SETUP SCREEN
'--------------------------------------------
PROC intro()
  CLS
  TEXT "SPACE PATROL" DIM 3 INK c.cyan TO 3.5*16,2*16
  TEXT "Neo6502" DIM 2 INK c.yellow TO 7.5*16,4*16
  CURSOR 0,11
  INK c.white
  PRINT " Defend your planet from an intergalactic invasion."
  PRINT "  You are in charge of a "+chr$(131)+"space patrol"+chr$(135)+" craft which"
  PRINT "  can move up and down the center of the screen."
  PRINT "  Moving the "+chr$(130)+"joystick"+chr$(135)+" to the left or right changes"
  PRINT "          the direction the ship is facing."
  PRINT " The "+chr$(129)+"fire button"+chr$(135)+" shoots torpedoes in the direction"
  PRINT "               your ship is pointing."
  PRINT "          (Or use the "+chr$(130)+"cursor keys"+chr$(135)+" + "+chr$(129)+"O"+chr$(135)+"/"+chr$(129)+"P"+chr$(135)+")"
  PRINT
  PRINT "  Prevent the invaders from landing on your planet."
  PRINT " When "+chr$(131)+"five alien ships"+chr$(135)+" reach the surface, you have"
  PRINT "            failed and the game is over."
  PRINT
  INK c.green
  PRINT "               PRESS ANY KEY TO PLAY"
  CALL playIntroTune()
ENDPROC

'============================================
'                             PLAY INTRO TUNE
'     Play tune for intro, wait for key press
'--------------------------------------------
PROC playIntroTune()
  LOCAL i
  i = 1
  REPEAT
    a$ = MID$(tune$,i,1)
    b$ = MID$(tune2$,i,1)
    CALL play2notes(a$, b$)
    i = i+1: IF i>tlen THEN i=1
  UNTIL INKEY$()<>""
ENDPROC

'============================================
'                              PLAY TWO NOTES
'     Play tune for intro, wait for key press
'--------------------------------------------
PROC play2notes(a$, b$)
  LOCAL f, f2, j
  f = 0: f2 = 0
  IF a$<>" "
    FOR j=0 TO 7
      IF a$=MID$(no$,j+1,1) THEN f=note(j)
    NEXT
    FOR j=0 TO 7
      IF b$=MID$(no$,j+1,1) THEN f2=note(j)
    NEXT
    IF f THEN SOUND 1,f,30: SOUND 3,f+5,20
    IF f2 THEN SOUND 2,f2/2,50
    WAIT 50
  ENDIF
ENDPROC

'============================================
'                                SETUP SCREEN
'--------------------------------------------
PROC setupScreen()
  CLS
  ' Create black sky
  RECT 0,0 SOLID INK c.black 319,239
  CALL putStars()
  CALL DrawTileMap(0,0)
  CALL updateScore()
  CALL updateLanded()
  CALL updateAmmo()
  CALL updateLevel()
ENDPROC

'============================================
'                                   PUT STARS
'                 Put random stars in the sky
'--------------------------------------------
PROC putStars()
  FOR i=1 TO 5
    c = RAND(20)
    r = RAND(11)+1
    IMAGE t.star TO c*16, r*16
  NEXT
  FOR i=1 TO 20
    c = RAND(20)
    r = RAND(11)+1
    IMAGE t.star+1 TO c*16, r*16
  NEXT
ENDPROC

'============================================
'                                SETUP ALIENS
'                Place alien ships in the sky
'--------------------------------------------
PROC setupAliens()
  LOCAL i, x, y, dup
  FOR i=0 TO 9
    REPEAT
      x = RAND(20)
    UNTIL x<9 | x>10
    REPEAT 
      y = RAND(5)+1
      CALL checkOverlap( x, y, dup )
    UNTIL dup=0
    xalien(i) = x
    yalien(i) = y
    SPRITE i+10 IMAGE s.alien TO x*16+8,y*16
  NEXT
ENDPROC

'============================================
'                               CHECK OVERLAP
'     Check if alien ship overlap with others
'--------------------------------------------
PROC checkOverlap(x, y, REF dup)
  LOCAL i
  dup = 0
  FOR i=0 TO 9
    IF y=yalien(i) & x=xalien(i) THEN dup = 1
  NEXT
ENDPROC

'============================================
'                                  PLAY AGAIN
'--------------------------------------------
PROC playAgain(REF yesno)
  LOCAL a$
  SPRITE CLEAR
  'CLS
  CURSOR 19,10
  PRINT "HIGH SCORE: ";highscore
  CURSOR 19,12
  PRINT "LAST SCORE: ";score
  CURSOR 19,14: INK c.yellow
  PRINT "PLAY AGAIN? (Y/N)"
  REPEAT
    a$ = INKEY$()
    a$ = UPPER$(a$)
  UNTIL a$="Y" | a$="N"
  IF a$="Y" THEN yesno = 1: SFX 0,3
  IF a$="N" THEN yesno = 0: SFX 0,5
  WAIT 100
ENDPROC

'============================================
'                              GAME OVER TUNE
'            Extended Neo6502 Game Over Theme
'--------------------------------------------
PROC tuneGameOver()
  SOUND CLEAR
  '  --- Phrase 1: the descent begins
  SOUND 0, 392, 40 : '  LEAD G4
  SOUND 1, 196, 40 : '  BASS G2
  SOUND 0, 349, 40 : '  LEAD F4
  SOUND 0, 311, 40 : '  LEAD EB4
  SOUND 1, 155, 40 : '  BASS EB2
  SOUND 0, 294, 40 : '  LEAD D4
  '  --- Phrase 2: shifting to minor keys
  SOUND 0, 311, 40 : '  LEAD EB4
  SOUND 1, 130, 40 : '  BASS C2
  SOUND 0, 261, 40 : '  LEAD C4
  SOUND 0, 246, 40 : '  LEAD B3
  SOUND 1, 123, 40 : '  BASS B1
  SOUND 0, 294, 40 : '  LEAD D4
  ' --- Phrase 3: dramatic slowdown ---
  SOUND 0, 261, 60 : '  LEAD C4 (LONGER)
  SOUND 1, 130, 60 : '  BASS C2 (LONGER)
  SOUND 0, 233, 60 : '  LEAD BB3
  SOUND 0, 207, 60 : '  LEAD AB3
  SOUND 1, 103, 60 : '  BASS AB1
  ' --- Phrase 4: final grim resolution ---
  SOUND 0, 196, 120 : '  FINAL G3 (HOLD FOR 1.2S)
  SOUND 1, 98,  120 : '  FINAL G1 BASS (DEEP RUMBLE)
  WAIT 450
ENDPROC

