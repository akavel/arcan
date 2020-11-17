function pipedream()
  -- show a colored rect in bottom-right corner
  local rect = color_surface(100, 100, 128, 128, 255)
  if not valid_vid(rect) then
    return shutdown("can't display rectangle")
  end
  local props = image_surface_properties(rect)
  show_image(rect)
  move_image(rect, VRESW - props.width, VRESH - props.height)

  -- TODO: launch_target with custom binary
  local vid, aid, cookie = launch_target(
    'test2', 'default',
    LAUNCH_INTERNAL,
    function(x, t)
      print("MCDBG", x)
      for k,v in pairs(t) do
        print("  ...", k, v)
      end
      reset_target(x)
    end)
  if not valid_vid(vid) then
    return shutdown("can't launch_target")
  end
  show_image(vid)
  target_displayhint(vid, 200, 200)
  reset_target(vid)
  local props = image_surface_properties(vid)
  for k,v in pairs(props) do
    print("PROP", k, v)
  end

  -- TODO: print error if above failed somehow

  print("hello dream 2!")
end

