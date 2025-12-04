# flycheck-ty
Flycheck files for ty

## To use

Run

```sh
uv tool install ty
```
or
```sh
python3 -m pip install ty
```
.

Add

```elisp
(load-file "/path/to/flycheck-astral/flycheck-ty.el")
(add-hook 'python-mode-hook 'flycheck-mode)
(add-hook 'python-ts-mode-hook 'flycheck-mode)
```

into your `.emacs` config file.

There are probably better ways of doing this, I am lazy.
