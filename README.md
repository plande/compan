# compan
Community "Package Manager" for [Guile](https://www.gnu.org/software/guile/)

## What is compan?
Compan is a tool for automatically fetching Guile modules from remote
Mercurial/Git repositories. It provides Guile with the `load-modules` macro
that can be used in the following ways:

```
;; clone the repository and load (lib) module from the top level:
(load-modules ("https://bitbucket.org/panicz/dogma" (lib)))

;; as above, but load modules from "libraries" directory:
(load-modules (("https://github.com/panicz/pamphlet" "libraries") (pamphlet)))

;; one can also fix on a particular tag/branch/commit:
(load-modules (("https://bitbucket.org/panicz/dogma" "." "3884445191c2") (lib)))
```

So, in general, the syntax of a single entry in ```load-modules``` takes
one of the following forms:

```
((url directory branch) modules ...)
((url directory) modules ...)
(url modules ...)
```

What the invocation of `load-module` actually does is that it clones
the repository to the `~/.guile.d/compan/` directory (unless already cloned),
extends the Guile's load path to be able to load modules from the specified
directory, loads the module, and then runs a separate thread to update
the repository.

## Installation

In order to install Compan, just copy the `compan.scm` file somewhere
to your Guile load path, and run `(use-modules (compan))` from within Guile.

Note that you need to have [Mercurial](https://www.mercurial-scm.org/)
installed for the Compan to work. If you want to be able to fetch
[Git](https://git-scm.com/) repositories, you'll need to install
[Hg-Git](http://hg-git.github.io/) extension to Mercurial.
