#! /bin/sh
make
cd build
./tp2 Gamma -i asm ../img/HardCandy.bmp
./tp2 Gamma -i c ../img/HardCandy.bmp
