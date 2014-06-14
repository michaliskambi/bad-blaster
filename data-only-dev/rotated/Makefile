DEGREE_STEP=2
RESULT_PATH=../../images/
ALL=$(RESULT_PATH)player_ship_strip.png \
  $(RESULT_PATH)comp_ship_strip.png \
  $(RESULT_PATH)rocket_strip.png

.PHONY: all clean

all: $(ALL)

$(RESULT_PATH)player_ship_strip.png: player_ship.png
	./mk_rotated_strip.sh $(DEGREE_STEP) $< $@ 
$(RESULT_PATH)comp_ship_strip.png: comp_ship.png
	./mk_rotated_strip.sh $(DEGREE_STEP) $< $@ 
$(RESULT_PATH)rocket_strip.png: rocket.png
	./mk_rotated_strip.sh $(DEGREE_STEP) $< $@ 

clean:
	rm -f $(ALL)