   10 REM Space Patrol for Agon BASIC
   20 REM Written for Agon but tried to be BBCSDL compatible
   30 REM
   40 REM Using MODE 2 (40x30) in AGON
   50 REM       MODE 8 (40x32) in FAB Agon emulator
   60 REM       MODE 9 (40x32) in BBSDL (Windows/Mac)
   70 REM
   80 REM To run on AGON LIGHT:
   90 REM   o Save this file as SPATROL.BAS in the AGON's SDCARD,
  100 REM     preferably in its BAS folder.
  110 REM   o On AGON, enter:
  120 REM        *CD BAS
  130 REM        LOAD "SPATROL.BAS"
  140 REM        RUN
  150 REM
  160 REM To run in FAB-agon-emulator:
  170 REM   o Copy this file as SPATROL.BAS in the sdcard\BAS subfolder
  180 REM     inside the Fab-agon-emulator-v0.9.77 folder.
  190 REM   o Enter the same commands as above.
  200 REM
  210 REM ---------------------------------------------------------------------
  220 REM V 0.50 - Optimize game loop
  230 REM ---------------------------------------------------------------------
  240 REM
  250 PROC_initialise
  260 PROC_setup
  270 PROC_intro
  280 play% = TRUE
  290 REPEAT
  300   PROC_initGame
  310   gameover% = FALSE
  320   count% = 0
  330   REPEAT
  340     PROC_getInput
  350     PROC_moveShip
  360     PROC_moveLandscape
  370     PROC_shootPhaser
  380     PROC_moveAlien
  390     REM PRINT TAB(0,1);col%;" "
  400     IF col%=11 AND row%=25 AND ammo%=0 THEN PROC_reloadAmmo
  410     count% = count%+1
  420     IF count%>interv% THEN count% = 0
  430     PROC_wait(2)
  440   UNTIL gameover%
  450   IF score%>hiscore% THEN hiscore% = score%
  460   play% = FN_playAgain
  470 UNTIL play% = FALSE
  480 CLS
  490 VDU 23,1,1;0;0;0;
  500 PRINT "BYE!"
  510 END
  520 REM
  530 REM ---------------------------------------------------------------------
  540 DEF PROC_initGame
  550 CLS
  560 REM place 10 alien ships randomly
  570 COLOUR YELLOW%
  580 FOR i=0 TO 9
  590   REPEAT
  600     REPEAT
  610       xalien(i) = RND(20)*2-2
  620     UNTIL xalien(i)<18 OR xalien(i)>20
  630     yalien(i) = RND(14)
  640     clashed = TRUE
  650     FOR j=1 TO 9
  660       IF i<>j AND xalien(i)<>xalien(j) AND xalien(i)<>xalien(j) THEN clashed = FALSE
  670     NEXT
  680   UNTIL clashed=FALSE
  690   PRINT TAB(xalien(i),yalien(i));CHR$(alien%)+CHR$(alien%+1);
  700 NEXT
  710 REM landscape
  720 PROC_printScape(1)
  730 COLOUR CYAN%
  740 PRINT TAB(0,28);o$;
  750 col% = 1: row% = 10: r% = 0: c% = 0: face% = 0
  760 level% = 1: score% = 0: ammo% = 20: landed = 0: spin% = 0: shoot% = 0
  770 COLOUR GREEN%
  780 PRINT TAB(0,0);"HIGH ";hiscore%
  790 PRINT TAB(15,0);"SCORE ";score%
  800 PRINT TAB(33,0);"LEVEL ";level%;
  810 PROC_updateAmmo
  820 ENDPROC
  830 REM
  840 REM ---------------------------------------------------------------------
  850 DEF PROC_printScape(k)
  860 COLOUR GREY%
  870 PRINT TAB(0,26);RIGHT$(m$,40-k);LEFT$(m$,k);
  880 a$ = RIGHT$(n$,40-k)+LEFT$(n$,k)
  890 FOR j=1 TO LEN(a$)
  900   COLOUR CYAN%
  910   b$ = MID$(a$,j,1): c = ASC(b$)
  920   IF c=tower%+2 OR c=tower%+3 THEN COLOUR GREY%
  930   PRINT b$;
  940 NEXT
  950 ENDPROC
  960 REM
  970 REM ---------------------------------------------------------------------
  980 DEF PROC_getInput
  990 k% = INKEY(0): REM IF k%>-1 THEN PRINT TAB(0,0);k%
 1000 IF k%=8 OR k%=136 OR k%=74 THEN c% =-1: face% = 0
 1010 IF k%=21 OR k%=137 OR k%=76 THEN c% = 1: face% = 2
 1020 IF k%=11 OR k%=139 OR k%=73 THEN r% =-1
 1030 IF k%=10 OR k%=138 OR k%=75 THEN r% = 1
 1040 IF k%=32 AND shoot%=0 THEN shoot% = 1
 1050 ENDPROC
 1060 REM
 1070 REM ---------------------------------------------------------------------
 1080 DEF PROC_moveShip
 1090 IF r%=0 THEN 1140
 1100 PRINT TAB(19,row%);"  ";
 1110 row% = row%+r%: r% = 0
 1120 IF row%<1 THEN row% = 1
 1130 IF row%>25 THEN row% = 25
 1140 IF ammo%>0 THEN COLOUR WHITE% ELSE COLOUR RED%
 1150 PRINT TAB(19,row%);CHR$(ship%+face%)+CHR$(ship%+1+face%);
 1160 ENDPROC
 1170 REM
 1180 REM ---------------------------------------------------------------------
 1190 DEF PROC_moveLandscape
 1200 IF c%=0 THEN ENDPROC
 1210 col% = col%+c%: c% = 0
 1220 IF col%<1 THEN col%=20
 1230 IF col%>20 THEN col%=1
 1240 PROC_printScape(col%)
 1250 ENDPROC
 1260 REM
 1270 REM ---------------------------------------------------------------------
 1280 DEF PROC_shootPhaser
 1290 IF shoot%=0 THEN ENDPROC
 1300 IF ammo%=0 THEN SOUND 1,-15,250,2: shoot%=0: ENDPROC
 1310 IF shoot%=2 THEN 1390
 1320 shoot% = 2
 1330 SOUND 0,-15,255,1
 1340 ammo% = ammo%-1
 1350 PROC_updateAmmo
 1360 py% = row%
 1370 px% = -18*(face%=0)-21*(face%=2)
 1380 hit% = 0: fc% = face%
 1390 COLOUR WHITE%
 1400 PRINT TAB(px%,py%);CHR$(phaser%)
 1410 FOR i%=0 TO 9
 1420   IF xalien(i%)=px% AND yalien(i%)=py% THEN hit% = i%+1
 1430 NEXT
 1440 IF hit% THEN PROC_explode(hit%-1): shoot% = 0: score% = score%+10*level%
 1450 IF score%=100 THEN level% = 2
 1460 IF score%=300 THEN level% = 3
 1470 IF score%=600 THEN level% = 4
 1480 IF score%=1000 THEN level% = 5
 1490 IF score%=1500 THEN level% = 6
 1500 IF score%=2100 THEN level% = 7
 1510 IF score%=2800 THEN level% = 8
 1520 IF score%=3600 THEN level% = 9
 1530 PROC_updateScore
 1540 PROC_wait(1)
 1550 PRINT TAB(px%,py%);" ";
 1560 IF fc%=0 THEN px% = px%-1 :IF px%<0 THEN shoot% = 0
 1570 IF fc%=2 THEN px% = px%+1 :IF px%>39 THEN shoot% = 0
 1580 ENDPROC
 1590 REM
 1600 REM ---------------------------------------------------------------------
 1610 DEF PROC_explode(i)
 1620 LOCAL x, y, k, v
 1630 x = xalien(i): y = yalien(i)
 1640 COLOUR RED%
 1650 PRINT TAB(x,y);CHR$(explode%)+CHR$(explode%+1)
 1660 SOUND 0,-15,0,2
 1670 PROC_wait(10)
 1680 PRINT TAB(x,y);"  "
 1690 yalien(i) = -1
 1700 ENDPROC
 1710 REM
 1720 REM ---------------------------------------------------------------------
 1730 DEF PROC_updateScore
 1740 COLOUR GREEN%
 1750 PRINT TAB(21,0);score%;" "
 1760 PRINT TAB(39,0);level%;
 1770 ENDPROC
 1780 REM
 1790 REM ---------------------------------------------------------------------
 1800 DEF PROC_reloadAmmo
 1810 LOCAL i, r%
 1820 FOR i=1 TO 20-2*level%
 1830   ammo% = i
 1840   PROC_updateAmmo
 1850   SOUND 1,-15,50+i*10,1
 1860 NEXT
 1870 PROC_wait(20)
 1880 REM move tower away + ship up
 1890 SOUND 0,-15,0,2
 1900 face% = 0: r% = row%
 1910 REPEAT
 1920   PROC_wait(5)
 1930   PRINT TAB(19,r%);"  ";
 1940   r% = r%-1
 1950   COLOUR WHITE%
 1960   PRINT TAB(19,r%);CHR$(ship%+face%)+CHR$(ship%+1+face%);
 1970   col% = col%-1
 1980   PROC_printScape(col%)
 1990 UNTIL r%=19
 2000 row% = r%
 2010 REPEAT UNTIL INKEY(0)=-1
 2020 ENDPROC
 2030 REM
 2040 REM ---------------------------------------------------------------------
 2050 DEF PROC_updateAmmo
 2060 LOCAL i
 2070 COLOUR RED%
 2080 IF ammo%=0 THEN PRINT TAB(0,29);" ";: ENDPROC
 2090 FOR i=1 TO ammo%: PRINT TAB(i-1,29);CHR$(phaser%+1);: NEXT
 2100 FOR i=ammo%+1 TO 20: PRINT TAB(i-1,29);" ";: NEXT
 2110 ENDPROC
 2120 REM
 2130 REM ---------------------------------------------------------------------
 2140 DEF PROC_moveAlien
 2150 IF count%<>0 THEN ENDPROC
 2160 LOCAL i, j, ch$
 2170 spin% = -2*(spin% = 0)
 2180 COLOUR YELLOW%
 2190 ch$ = CHR$(alien%+spin%)+CHR$(alien%+1+spin%)
 2200 FOR i=0 TO 9
 2210   IF yalien(i)>0 THEN PRINT TAB(xalien(i),yalien(i));ch$;
 2220 NEXT
 2230 FOR j=1 TO level%+1
 2240   i = RND(10)-1
 2250   PRINT TAB(xalien(i),yalien(i));"  ";
 2260   IF yalien(i)=-1 THEN PROC_newAlien(i)
 2270   yalien(i) = yalien(i)+1
 2280   IF FN_clashed(i) THEN yalien(i) = yalien(i)+1
 2290   COLOUR YELLOW%
 2300   PRINT TAB(xalien(i),yalien(i));ch$;
 2310   IF yalien(i)>25 THEN yalien(i)=-1: PROC_alienLand(i): PROC_printScape(col%)
 2320 NEXT
 2330 ENDPROC
 2340 REM
 2350 REM ---------------------------------------------------------------------
 2360 DEF PROC_newAlien(i)
 2370 yalien(i) = 1
 2380 REPEAT
 2390   xalien(i) = RND(20)*2-2
 2400 UNTIL xalien(i)<18 OR xalien(i)>20
 2410 ENDPROC
 2420 REM
 2430 REM ---------------------------------------------------------------------
 2440 DEF FN_clashed(n)
 2450 LOCAL clash, i
 2460 clash = FALSE
 2470 FOR i=0 TO 9
 2480   IF i<>n AND xalien(i)=xalien(n) AND yalien(i)=yalien(n) THEN clash = TRUE
 2490 NEXT
 2500 =clash
 2510 REM
 2520 REM ---------------------------------------------------------------------
 2530 DEF PROC_alienLand(i)
 2540 LOCAL start%
 2550 COLOUR GREEN%
 2560 PRINT TAB(xalien(i),27);CHR$(alien%+4)+CHR$(alien%+5);
 2570 SOUND 1,-15,1,20
 2580 landed = landed+1
 2590 PROC_wait(100)
 2600 PROC_updateLanded
 2610 IF landed = 5 THEN gameover%=TRUE
 2620 ENDPROC
 2630 REM
 2640 REM ---------------------------------------------------------------------
 2650 DEF PROC_updateLanded
 2660 LOCAL i
 2670 COLOUR GREEN%
 2680 IF landed>0 THEN FOR i=1 TO landed: PRINT TAB(27+i*2,29);CHR$(alien%+4)+CHR$(alien%+5);: NEXT
 2690 ENDPROC
 2700 REM
 2710 REM ---------------------------------------------------------------------
 2720 DEF PROC_setup
 2730 DIM xalien(9), yalien(9)
 2740 LOCAL a$, t$, u$
 2750 PROC_customchar
 2760 m$ = "          AB                  AB        "
 2770 n$ = "LEFGHIJKLMCDFGHIJKLEIKLEFGHJKMCDEFGHIJKL"
 2780 t$ = "": u$ = ""
 2790 FOR i=1 TO LEN(m$)
 2800   a$ = MID$(m$,i,1)
 2810   IF a$=" " THEN t$ = t$+a$
 2820   IF a$<>" " THEN t$ = t$+CHR$(ASC(a$)+tower%-65)
 2830   a$ = MID$(n$,i,1)
 2840   IF a$=" " THEN u$ = u$+a$
 2850   IF a$<>" " THEN u$ = u$+CHR$(ASC(a$)+tower%-65)
 2860 NEXT
 2870 m$ = t$: n$ = u$
 2880 o$ = ""
 2890 FOR i=1 TO 40
 2900   o$ = o$+CHR$(scape%+9)
 2910 NEXT
 2920 IF machine$="SDL" THEN interv%=30 ELSE interv%=30
 2930 hiscore% = 0: score% = 0
 2940 ENDPROC
 2950 REM
 2960 REM ---------------------------------------------------------------------
 2970 DEF PROC_intro
 2980 LOCAL b$,i,n
 2990 DIM a$(9)
 3000 a$(0) = " ##### #####   ####   ####  ######"
 3010 a$(1) = "##     ##  ## ##  ## ##  ## ##"
 3020 a$(2) = " ###   #####  ###### ##     ####"
 3030 a$(3) = "    ## ##     ##  ## ##  ## ##"
 3040 a$(4) = "#####  ##     ##  ##  ####  ######"
 3050 a$(5) = "#####   #### ###### #####   ####  ##"
 3060 a$(6) = "##  ## ##  ##  ##   ##  ## ##  ## ##"
 3070 a$(7) = "#####  ######  ##   ####   ##  ## ##"
 3080 a$(8) = "##     ##  ##  ##   ## ##  ##  ## ##"
 3090 a$(9) = "##     ##  ##  ##   ##  ##  ####  #####"
 3100 FOR n=0 TO 9
 3110   b$ = ""
 3120   FOR i=1 TO LEN(a$(n))
 3130     IF MID$(a$(n),i,1)=" " THEN b$=b$+" " ELSE b$=b$+CHR$(129)
 3140   NEXT
 3150   a$(n) = b$
 3160 NEXT
 3170 PRINT TAB(0,4)
 3180 FOR i=0 TO 4
 3190   COLOUR i+2
 3200   PRINT TAB(2);a$(i)
 3210 NEXT
 3220 PRINT
 3230 FOR i=5 TO 9
 3240   COLOUR i+4
 3250   PRINT a$(i)
 3260 NEXT
 3270 COLOUR DGREY%: PRINT TAB(33);machine$;" ";interv%;
 3280 PRINT: PRINT: PRINT
 3290 COLOUR WHITE%
 3300 PRINT TAB(8);"USE CURSOR KEYS TO MOVE"
 3310 PRINT TAB(8);"  UP/DOWN/LEFT/RIGHT"
 3320 COLOUR GREY%
 3330 PRINT TAB(8);"PRESS SPACE BAR TO SHOOT"
 3340 k = INKEY(1000)
 3350 ENDPROC
 3360 REM
 3370 REM ---------------------------------------------------------------------
 3380 DEF PROC_initialise
 3390 machine$ = FN_whichMachine
 3400 IF machine$="SDL" THEN MODE 9
 3410 IF machine$="BBC32" THEN MODE 4
 3420 IF machine$="Agon" THEN MODE 2
 3430 IF machine$="emu" THEN MODE 8
 3440 VDU 23, 0, 10, 32 : REM Switch OFF the cursor
 3450 REM Colours
 3460 BLACK%=0: DRED%=1: GREEN%=2: GOLD%=3: DBLUE%=4: PURPLE%=5: CYAN%=6 :GREY%=7
 3470 DGREY%=8: RED%=9: LGREEN%=10: YELLOW%=11: BLUE%=12: MAGENTA%=13: AQUA%=14: WHITE%=15
 3480 ENDPROC
 3490 REM
 3500 REM ---------------------------------------------------------------------
 3510 DEF FN_whichMachine
 3520 LOCAL mach$
 3530 IF HIMEM<=31744 THEN mach$ = "BBC32": = mach$
 3540 IF HIMEM<>65280 THEN mach$ = "SDL": = mach$
 3550 IF GET(128)=12 THEN mach$="Agon" ELSE mach$="emu"
 3560 = mach$
 3570 REM
 3580 REM ---------------------------------------------------------------------
 3590 DEF PROC_wait(ms)
 3600 LOCAL t%
 3610 t% = TIME
 3620 REPEAT UNTIL (TIME - t%) >= ms
 3630 ENDPROC
 3640 REM
 3650 REM ---------------------------------------------------------------------
 3660 DEF PROC_customchar
 3670 ship% = 227
 3680 VDU 23,ship%, 0,0,0,0,0,0,0,0             :REM blank?
 3690 VDU 23,ship%, 0,0,0,15,23,127,0,5
 3700 VDU 23,ship%+1, 63,14,62,255,255,255,56,254
 3710 VDU 23,ship%+2, 252,112,124,255,255,255,28,127   :REM ship rightt 1
 3720 VDU 23,ship%+3, 0,0,0,240,232,254,0,160     :REM ship right 2
 3730 phaser% = ship%+4
 3740 VDU 23,phaser%, 0,0,0,0,0,90,0,0             :REM phaser
 3750 VDU 23,phaser%+1, 0,4,14,14,14,4,14,10       :REM ammo
 3760 alien% = phaser%+2
 3770 VDU 23,alien%, 0,15,15,27,63,127,13,8          :REM alien ship 1
 3780 VDU 23,alien%+1, 0,240,240,120,252,254,176,16
 3790 VDU 23,alien%+2, 0,15,15,30,63,127,13,8     :REM alien ship 2
 3800 VDU 23,alien%+3, 0,240,240,216,252,254,176,16
 3810 VDU 23,alien%+4, 28,20,8,62,93,93,20,20       :REM alien couple
 3820 VDU 23,alien%+5, 56,40,144,252,58,58,40,40
 3830 explode% = alien%+6
 3840 VDU 23,explode%, 4,81,4,16,65,20,1,36        :REM explode 1
 3850 VDU 23,explode%+1, 68,16,133,16,68,17,4,72   :REM explode 2
 3860 tower% = explode%+2
 3870 VDU 23,tower%, 127,217,209,127,2,2,6,7        :REM Top left A
 3880 VDU 23,tower%+1, 254,155,139,254,64,64,96,224 :REM top right
 3890 VDU 23,tower%+2, 6,14,14,15,12,28,28,31       :REM Tower left
 3900 VDU 23,tower%+3, 96,112,112,240,48,56,56,248  :REM Tower right
 3910 scape% = tower%+4
 3920 VDU 23,scape%, 0,0,2,3,15,31,63,255             :REM lanscape 1 E
 3930 VDU 23,scape%+1, 1,3,7,15,159,255, 255, 255     :REM lanscape 2
 3940 VDU 23,scape%+2, 0,128,192,192,224,227,247,255  :REM lanscape 3
 3950 VDU 23,scape%+3, 0,4,14,63,255,255,255,255      :REM lanscape 4
 3960 VDU 23,scape%+4, 4,6,15,191,255,255,255,255     :REM lanscape 5
 3970 VDU 23,scape%+5, 0,48,242,255,255,255,255, 255  :REM lanscape 6
 3980 VDU 23,scape%+6, 0,0,0,129,195,231,255,255      :REM lanscape 7
 3990 VDU 23,scape%+7, 32,112,248,252,254,255, 255,255 :REM lanscape 8
 4000 VDU 23,scape%+8, 0,0,0,32,112,248,252,255       :REM lanscape 9  M
 4010 block% = scape%+9
 4020 VDU 23,block%, 255,255,255,255,255,255,255,255 :REM BLOCK
 4030 VDU 23,block%+1, 0,0,0,0,0,0,0,0       :REM blank
 4040 ENDPROC
 4050 REM
 4060 REM ---------------------------------------------------------------------
 4070 DEF FN_playAgain
 4080 LOCAL i
 4090 a$ = ""
 4100 FOR i=1 TO 21: a$ = a$+CHR$(scape%+9): NEXT
 4110 COLOUR RED%
 4120 FOR i=7 TO 19: PRINT TAB(9,i);a$: NEXT
 4130 FOR i=8 TO 18: PRINT TAB(10,i);"                   ": NEXT
 4140 PRINT TAB(10,9);" G A M E   O V E R "
 4150 PROC_tuneGameOver
 4160 COLOUR WHITE%
 4170 PRINT TAB(10,12);" SCORE:     ";score%
 4180 PRINT TAB(10,14);" HIGH SCORE:";hiscore%
 4190 PRINT TAB(10,17);" Play again? [Y/N] "
 4200 answer = FALSE
 4210 REPEAT
 4220   a$ = INKEY$(0)
 4230 UNTIL a$="Y" OR a$="y" OR a$="N" OR a$="n"
 4240 IF a$="Y" OR a$="y" THEN answer = TRUE
 4250 = answer
 4260 REM
 4270 REM ---------------------------------------------------------------------
 4280 REM PLAY GAME OVER TUNE
 4290 DEF PROC_tuneGameOver
 4300 SOUND 1, -6, 52, 10: SOUND 2, -6, 48, 10
 4310 SOUND 1, -7, 48, 10: SOUND 2, -6, 44, 10
 4320 SOUND 1, -8, 44, 10: SOUND 2, -6, 36, 10
 4330 SOUND 1, -9, 36, 25: SOUND 2, -6, 28, 10
 4340 PROC_wait(200)
 4350 ENDPROC
 4360 REM
 4370 REM ---------------------------------------------------------------------
