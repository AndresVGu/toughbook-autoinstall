#!/bin/sh

#-----DEVICE NAME----------

DEVICE="Fujitsu Component USB Touch Panel"

#-------Escala----------

SCALE_X=1.10     # >1 expande, <1 encoge en X
SCALE_Y=1.15     # >1 expande, <1 encoge en Y 

#---------Offset----------

OFFSET_X=-0.045    #Negativo = mueve a la izquierda
OFFSET_Y=-0.085    #Negativo = mueve hacia arriba 

MATRIX="$SCALE_X 0 $OFFSET_X 0 $SCALE_Y $OFFSET_Y 0 0 1"

#---Command--------
xinput set-prop "$DEVICE" --type=float "Coordinate Transformation Matrix" $MATRIX

#---------Matrix VIEW EXAMPLE--------

#| SCALE_X    0      OFFSET_X |
#|    0     SCALE_Y      0    | 
#|    0       0          1    |
