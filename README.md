# lisppi-mouse

Reads mouse position, wheel and button data using Linux evdev.

# Quickstart

To use inside some main loop, initialize with `(mouse:open)`.  Call `(mouse:handle-events #'fun)` with your callback function that receives x, y, wheel, button-middle, button-right and button-right status.  The call will process all mouse events accumulated by the system and call your callback.  When finished, call `(mouse:close`).



