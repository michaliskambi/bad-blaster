#! /bin/sh

set -eu

# Wywolaj z trzema parametrami:
#   DEGREE_STEP IMG_0 RESULT_PATH
# DEGREE_STEP : co ile stopni generowac image, musi dzielic 360
# IMG_0 : poczatkowy image
# RESULT_PATH : result path, obrazki o nazwach
#   `stringoper AppendToFileName "$IMG_0" _rotateDEGREE`
#   dla DEGREE = DEGREE_STEP * k (k = 0,1, ...),
#   dla k = 0 mamy DEGREE = 0 mamy obrazek
#   `stringoper AppendToFileName "$IMG_0" _rotate0`
#   ktory jest rowny IMG_0
#
# Kolejne obrazki z coraz wiekszym k to obrazki obrocone o DEGREE_STEP*k
# stopni CCW. Po obroceniu wycinamy z obrazka srodek o takich rozmiarach
# jakie ma IMG_0 wiec wszystkie wygenerowane obrazki maja taki sam
# rozmiar jak IMG_0. W wyniku obracania na obrazku pojawiaja sie tez
# nowe obszary (ktore nie wziely swojego koloru z zadnego koloru
# obrazka IMG_0) - te obszary beda mialy kolor #ffff (patrz ImageMagick
# -fill), czyli przezroczysty bialy.
#
# W czasie generowania wypisywane sa pewne informacje na stdout,
# w razie bledu powinien zostac wypisany odpowiedni komunikat
# na stdout/stderr i skrypt zakonczy sie z wynikiem <> 0.

DEGREE_STEP="$1"
IMG_0="$2"
RESULT_PATH="$3"
# set ADD_BORDER_RECT to something non-zero-length to make this script
# draw a white border on every image. This can be useful for testing
# purposes (at this time I don't see any need to expose this parameter
# to be settable using command-line params to this script but it 
# may change at some time)
ADD_BORDER_RECT=''

IMG_0_WIDTH=`identify -format %w "$IMG_0"`
IMG_0_HEIGHT=`identify -format %h "$IMG_0"`

DEGREE=0
while let 'DEGREE < 360'; do
  IMG_RESULT="${RESULT_PATH}"`stringoper AppendToFileName "$IMG_0" _rotate$DEGREE`
  echo -n "$IMG_RESULT..."

  convert "$IMG_0" -background '#ffff' -rotate -$DEGREE "$IMG_RESULT"

  # Teraz trzeba poprawic IMG_RESULT, wycinajac z niego srodkowa
  # czesc IMG_0_WIDTH x IMG_0_HEIGHT pixli.
  #
  # Za pierwszym razem zrobilem to przy pomocy -shave, ale teraz
  # widze ze shave nie jest dobre: -shave obcina tyle samo pixli
  # zarowno z lewej jak i z prawej strony, a to moze sprawic ze
  # niektore obrazki wynikowe beda mialy szerokosc $IMG_0_WIDTH+1
  # zamiast $IMG_0_WIDTH. Oczywiscie podobnie dla height.
  #
  # Dobrym rozwiazaniem jest oczywiscie -crop.
  IMG_RESULT_WIDTH=`identify -format %w "$IMG_RESULT"`
  IMG_RESULT_HEIGHT=`identify -format %h "$IMG_RESULT"`
  set +e
    let 'CROP_X0 = ( IMG_RESULT_WIDTH - IMG_0_WIDTH ) / 2'
    let 'CROP_Y0 = ( IMG_RESULT_HEIGHT - IMG_0_HEIGHT ) / 2'
  set -e
  echo -n " generated, cropping (${CROP_X0},${CROP_Y0})..."

  convert "$IMG_RESULT" -crop \
    ${IMG_0_WIDTH}x${IMG_0_HEIGHT}+${CROP_X0}+${CROP_Y0} "$IMG_RESULT"

  if [ "$ADD_BORDER_RECT" ]; then
    set +e
      let 'A = IMG_0_WIDTH-1'
      let 'B = IMG_0_HEIGHT-1'
    set -e
    convert "$IMG_RESULT" -stroke '#fff0' \
      -draw "line 0,0 $A,0" -draw "line 0,$B $A,$B" \
      -draw "line 0,0 0,$B" -draw "line $A,0 $A,$B" "$IMG_RESULT"
  fi

  echo ' done.'

  let 'DEGREE = DEGREE + DEGREE_STEP'
done

let 'IMAGES_MADE_COUNT = 360 / DEGREE_STEP'
echo "Done $IMAGES_MADE_COUNT images."