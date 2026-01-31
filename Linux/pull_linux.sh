mkdir Linux && cd Linux
curl -s https://api.github.com/repos/pwngineers/CCDC2024/contents/Linux | \
  grep '"download_url"' | \
  cut -d '"' -f 4 | \
  xargs -n1 curl -O