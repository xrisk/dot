function twitch
      streamlink --stdout $argv[1] best | iina --stdin
end
