# MirageOS simple http server

Made for serving remark presentations, as an exercise being actually
copied from https://github.com/mirage/mirage-skeleton

## Installation && test run

Important: you should install && use OPAM v2.

``` shell
$ opam switch create . ocaml-base-compiler
$ opam install mirage merlin
$ mirage configure -t macosx
$ make depend
$ make
```

NB: Merlin is being installed as a development dependency. You may
need it if you want to play with the sources. Othewise it may be omitted.

## NB: the slides

I've added some slides in `presentation` dir so you can see how I
presented this experiment on **f(by)** conference. And, btw, may you
teach me how to avoid that crazy console output colouring in `remark`?
