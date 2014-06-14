# sorry, should be calculated
IMG_RESULT_MASK='ship1_rotate*.png'
IMG_MONTAGED_RESULT=ship1_montaged.png


let 'IMG_RESULT_COUNT = 360 / DEGREE_STEP'
echo -n "$IMG_RESULT_COUNT images done, montage'ing... "

# sorry - images ponizej laduja w zlej kolejnosci i ich alpha channel 
# jest tracony

montage -tile "${IMG_RESULT_COUNT}x1" \
  -background '#ffff' \
  -geometry "${IMG_0_WIDTH}x${IMG_0_HEIGHT}" \
  "$IMG_RESULT_MASK" "$IMG_MONTAGED_RESULT"

echo ' done'