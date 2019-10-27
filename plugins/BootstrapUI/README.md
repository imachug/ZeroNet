# BootstrapUI

BootstrapUI is a plugin that simplifies ZeroNet client bootstrapping.


## Why?

ZeroNet uses virtual domain names like `talk.zeronetwork.bit.zero` or
`1hello4uzjaletfx6nh3pmwfp3qbrbtf3d.zero` to separate sites from each other and
help prevent vulnerabilities. However, enabling such names requires non-obvious
actions. This plugin helps to make them easier.


## How?

By default, ZeroNet maps UI to TCP port 43110, with bootstrap UI hosted on URL
`/bootstrap/`. `http://127.0.0.1:43110/bootstrap/` is opened in browser when
ZeroNet starts. That page then checks what browser is used and helps to install
extension.


## Usecases

### Local ZeroNet

ZeroNet will open `http://127.0.0.1:43110/bootstrap/` in the default browser.
Follow the instructions. If the browser wasn't opened for some reason or you
want to set up another browser, you can navigate
`http://127.0.0.1:43110/bootstrap/` manually.


## ZeroNet in LAN

If you want to access your ZeroNet instance from a different computer in LAN,
you'll have to access `http://192.168.0.7:43110/bootstrap/` (or another IP or
port) and configure the extension to access `192.168.0.7:43110` instead of
`127.0.0.1:43110`.


## ZeroNet proxies

ZeroNet proxies have to set UI port 80 (with `--ui_port 80`) and wildcard
domains such as `*.my.zerobox.com` (with `--ui_host my.zerobox.com`). This
allows seamless ZeroNet access to ZeroNet sites with
`talk.zeronetwork.bit.my.zerobox.com` or
`1hello4uzjaletfx6nh3pmwfp3qbrbtf3d.my.zerobox.com`.